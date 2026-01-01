#!/usr/bin/env bash

# ==========================================
# SECURE DOTFILES INSTALLATION SCRIPT
# ==========================================
# Security-first dotfiles installer with comprehensive checks
# Author: Your Name
# Version: 1.0.0

set -euo pipefail  # Exit on error, undefined vars, pipe failures

# ==========================================
# CONFIGURATION
# ==========================================

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$HOME/.dotfiles_install.log"

# Interactive mode: auto-disable in CI/Codespaces environments
INTERACTIVE="${INTERACTIVE:-true}"
if [[ -n "${CODESPACES:-}" ]] || [[ -n "${CI:-}" ]] || [[ ! -t 0 ]]; then
    INTERACTIVE="false"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ==========================================
# LOGGING FUNCTIONS
# ==========================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"

    case "$level" in
        "ERROR")   echo -e "${RED}❌ $message${NC}" ;;
        "WARN")    echo -e "${YELLOW}⚠️  $message${NC}" ;;
        "INFO")    echo -e "${CYAN}ℹ️  $message${NC}" ;;
        "SUCCESS") echo -e "${GREEN}✅ $message${NC}" ;;
        "DEBUG")   echo -e "${BLUE}🔍 $message${NC}" ;;
        *)         echo "$message" ;;
    esac
}

# Log non-interactive mode detection
if [[ "$INTERACTIVE" == "false" ]]; then
    log "INFO" "Running in non-interactive mode (CI/Codespaces detected)"
fi

# ==========================================
# SECURITY FUNCTIONS
# ==========================================

# Check if running as root (security risk)
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        log "ERROR" "This script should not be run as root for security reasons"
        log "INFO" "Run as your regular user account"
        exit 1
    fi
}

# Scan for existing secrets in files
scan_for_secrets() {
    local target="$1"
    local found_secrets=false

    log "INFO" "Scanning for exposed secrets in: $target"

    # Common secret patterns
    local patterns=(
        "password.*=.*['\"][^'\"]{8,}['\"]"
        "api[_-]?key.*=.*['\"][^'\"]{20,}['\"]"
        "secret.*=.*['\"][^'\"]{20,}['\"]"
        "token.*=.*['\"][^'\"]{20,}['\"]"
        "aws[_-]?access[_-]?key[_-]?id.*['\"][A-Z0-9]{20}['\"]"
        "aws[_-]?secret[_-]?access[_-]?key.*['\"][A-Za-z0-9/+=]{40}['\"]"
        "private[_-]?key.*BEGIN.*PRIVATE.*KEY"
        "ssh[_-]?rsa.*PRIVATE.*KEY"
    )

    for pattern in "${patterns[@]}"; do
        if command -v rg &>/dev/null; then
            # Use ripgrep if available (faster)
            if rg -i "$pattern" "$target" --type-not binary &>/dev/null; then
                found_secrets=true
                break
            fi
        else
            # Fallback to grep
            if grep -r -i -E "$pattern" "$target" --exclude-dir=.git 2>/dev/null | head -1 | grep -q .; then
                found_secrets=true
                break
            fi
        fi
    done

    if [[ "$found_secrets" == "true" ]]; then
        log "WARN" "Potential secrets detected in existing files!"
        log "WARN" "Please review your existing dotfiles for exposed credentials"

        if [[ "$INTERACTIVE" == "true" ]]; then
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log "INFO" "Installation cancelled"
                exit 1
            fi
        else
            log "WARN" "Non-interactive mode: proceeding despite potential secrets"
        fi
    else
        log "SUCCESS" "No obvious secrets found in existing files"
    fi
}

# Validate file permissions
check_file_permissions() {
    local file="$1"
    local expected_perms="$2"

    if [[ -f "$file" ]]; then
        local actual_perms
        if [[ "$OSTYPE" == "darwin"* ]]; then
            actual_perms=$(stat -f "%A" "$file")
        else
            actual_perms=$(stat -c "%a" "$file")
        fi

        if [[ "$actual_perms" != "$expected_perms" ]]; then
            log "WARN" "File $file has permissions $actual_perms, expected $expected_perms"
            return 1
        fi
    fi
    return 0
}

# ==========================================
# SYSTEM CHECKS
# ==========================================

# Check system requirements
check_requirements() {
    log "INFO" "Checking system requirements..."

    local missing_deps=()

    # Essential tools
    if ! command -v git &>/dev/null; then
        missing_deps+=("git")
    fi

    if ! command -v curl &>/dev/null; then
        missing_deps+=("curl")
    fi

    # Check for package manager
    local has_package_manager=false
    if command -v brew &>/dev/null; then
        has_package_manager=true
        log "INFO" "Homebrew detected"
    elif command -v apt &>/dev/null; then
        has_package_manager=true
        log "INFO" "APT detected"
    elif command -v yum &>/dev/null; then
        has_package_manager=true
        log "INFO" "YUM detected"
    fi

    if [[ "$has_package_manager" == "false" ]]; then
        log "WARN" "No supported package manager found"
    fi

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log "ERROR" "Missing required dependencies: ${missing_deps[*]}"
        log "INFO" "Please install them before running this script"
        exit 1
    fi

    log "SUCCESS" "System requirements satisfied"
}

# Check existing shell configuration
check_existing_config() {
    log "INFO" "Checking existing shell configuration..."

    local config_files=(".zshrc" ".bashrc" ".bash_profile" ".profile")
    local found_configs=()

    for config in "${config_files[@]}"; do
        if [[ -f "$HOME/$config" ]]; then
            found_configs+=("$config")
        fi
    done

    if [[ ${#found_configs[@]} -gt 0 ]]; then
        log "INFO" "Found existing configuration files: ${found_configs[*]}"
        log "INFO" "These will be backed up to: $BACKUP_DIR"
    fi
}

# ==========================================
# INSTALLATION FUNCTIONS
# ==========================================

# Create backup directory
create_backup() {
    log "INFO" "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"

    # Backup existing files
    local files=(".zshrc" ".bashrc" ".bash_profile" ".profile" ".gitconfig" ".gitignore_global")

    for file in "${files[@]}"; do
        if [[ -f "$HOME/$file" ]]; then
            log "INFO" "Backing up $file"
            cp "$HOME/$file" "$BACKUP_DIR/"
        fi
    done

    log "SUCCESS" "Backup created in $BACKUP_DIR"
}

# Install Oh My Zsh if not present
install_oh_my_zsh() {
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log "INFO" "Installing Oh My Zsh..."

        # Download and install Oh My Zsh
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

        if [[ -d "$HOME/.oh-my-zsh" ]]; then
            log "SUCCESS" "Oh My Zsh installed successfully"
        else
            log "ERROR" "Failed to install Oh My Zsh"
            exit 1
        fi
    else
        log "INFO" "Oh My Zsh already installed"
    fi
}

# Install Oh My Zsh plugins
install_zsh_plugins() {
    log "INFO" "Installing additional Zsh plugins..."

    local custom_plugins_dir="$HOME/.oh-my-zsh/custom/plugins"

    # zsh-autosuggestions
    if [[ ! -d "$custom_plugins_dir/zsh-autosuggestions" ]]; then
        log "INFO" "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$custom_plugins_dir/zsh-autosuggestions"
    fi

    # zsh-syntax-highlighting
    if [[ ! -d "$custom_plugins_dir/zsh-syntax-highlighting" ]]; then
        log "INFO" "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$custom_plugins_dir/zsh-syntax-highlighting"
    fi

    log "SUCCESS" "Zsh plugins installed"
}

# Symlink dotfiles
symlink_files() {
    log "INFO" "Creating symlinks for dotfiles..."

    local files=(
        ".zshrc"
        ".gitignore.global"
    )

    for file in "${files[@]}"; do
        local source_file="$DOTFILES_DIR/$file"
        local target_file="$HOME/$file"

        if [[ -f "$source_file" ]]; then
            # Remove existing file/symlink
            if [[ -e "$target_file" ]] || [[ -L "$target_file" ]]; then
                rm -f "$target_file"
            fi

            # Create symlink
            ln -s "$source_file" "$target_file"
            log "INFO" "Symlinked $file"
        else
            log "WARN" "Source file not found: $source_file"
        fi
    done

    # Symlink config directory
    local config_source="$DOTFILES_DIR/config"
    local config_target="$HOME/config"

    if [[ -d "$config_source" ]]; then
        if [[ -e "$config_target" ]] || [[ -L "$config_target" ]]; then
            rm -rf "$config_target"
        fi
        ln -s "$config_source" "$config_target"
        log "INFO" "Symlinked config directory"
    fi

    log "SUCCESS" "Symlinks created"
}

# Setup secrets file
setup_secrets() {
    local secrets_file="$HOME/.secrets"
    local secrets_template="$DOTFILES_DIR/.secrets.template"

    if [[ ! -f "$secrets_file" ]]; then
        if [[ -f "$secrets_template" ]]; then
            log "INFO" "Creating .secrets file from template"
            cp "$secrets_template" "$secrets_file"
            chmod 600 "$secrets_file"
            log "SUCCESS" ".secrets file created with secure permissions (600)"
            log "INFO" "Edit ~/.secrets to add your actual secrets"
        else
            log "WARN" "No .secrets template found"
        fi
    else
        log "INFO" ".secrets file already exists"

        # Check permissions
        if ! check_file_permissions "$secrets_file" "600"; then
            log "WARN" "Fixing .secrets file permissions"
            chmod 600 "$secrets_file"
        fi
    fi
}

# Configure Git
configure_git() {
    log "INFO" "Configuring Git..."

    # Set global gitignore
    git config --global core.excludesfile "$HOME/.gitignore.global"
    log "INFO" "Global gitignore configured"

    # Other useful Git configurations
    git config --global init.defaultBranch main
    git config --global pull.rebase false
    git config --global push.default simple
    git config --global core.autocrlf input

    # Check if user info is set
    if ! git config --global user.name &>/dev/null; then
        if [[ "$INTERACTIVE" == "true" ]]; then
            read -p "Enter your Git name: " git_name
            git config --global user.name "$git_name"
        else
            log "INFO" "Skipping Git user.name configuration (non-interactive mode)"
        fi
    fi

    if ! git config --global user.email &>/dev/null; then
        if [[ "$INTERACTIVE" == "true" ]]; then
            read -p "Enter your Git email: " git_email
            git config --global user.email "$git_email"
        else
            log "INFO" "Skipping Git user.email configuration (non-interactive mode)"
        fi
    fi

    log "SUCCESS" "Git configured"
}

# Install development tools
install_dev_tools() {
    log "INFO" "Checking development tools..."

    # Tools to install/check
    local tools=(
        "fnm:Fast Node Manager:curl -fsSL https://fnm.vercel.app/install | bash"
        "pyenv:Python Version Manager:curl https://pyenv.run | bash"
    )

    for tool_info in "${tools[@]}"; do
        IFS=':' read -r tool_name tool_desc tool_install <<< "$tool_info"

        if ! command -v "$tool_name" &>/dev/null; then
            if [[ "$INTERACTIVE" == "true" ]]; then
                read -p "Install $tool_desc? (y/N): " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    log "INFO" "Installing $tool_desc..."
                    eval "$tool_install"
                    log "SUCCESS" "$tool_desc installed"
                fi
            else
                log "INFO" "Skipping $tool_desc installation (non-interactive mode)"
            fi
        else
            log "INFO" "$tool_desc already installed"
        fi
    done
}

# Set Zsh as default shell
set_default_shell() {
    local current_shell=$(basename "$SHELL")

    if [[ "$current_shell" != "zsh" ]]; then
        log "INFO" "Current shell is $current_shell"

        if [[ "$INTERACTIVE" == "true" ]]; then
            read -p "Set Zsh as your default shell? (y/N): " -n 1 -r
            echo

            if [[ $REPLY =~ ^[Yy]$ ]]; then
                local zsh_path
                if command -v zsh &>/dev/null; then
                    zsh_path=$(which zsh)

                    # Add zsh to /etc/shells if not present
                    if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
                        log "INFO" "Adding Zsh to /etc/shells (requires sudo)"
                        echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
                    fi

                    # Change default shell
                    log "INFO" "Changing default shell to Zsh (requires sudo)"
                    sudo chsh -s "$zsh_path" "$USER"

                    log "SUCCESS" "Default shell changed to Zsh"
                    log "INFO" "You may need to restart your terminal or log out/in"
                else
                    log "ERROR" "Zsh not found in PATH"
                fi
            fi
        else
            log "INFO" "Skipping shell change (non-interactive mode)"
            log "INFO" "Zsh should already be configured by the devcontainer"
        fi
    else
        log "INFO" "Zsh is already your default shell"
    fi
}

# ==========================================
# VALIDATION FUNCTIONS
# ==========================================

# Validate installation
validate_installation() {
    log "INFO" "Validating installation..."

    local errors=0

    # Check symlinks
    local files=(".zshrc" "config")
    for file in "${files[@]}"; do
        if [[ ! -L "$HOME/$file" ]]; then
            log "ERROR" "Symlink not found: $HOME/$file"
            ((errors++))
        fi
    done

    # Check .secrets permissions
    if [[ -f "$HOME/.secrets" ]]; then
        if ! check_file_permissions "$HOME/.secrets" "600"; then
            log "ERROR" "Incorrect permissions on .secrets file"
            ((errors++))
        fi
    fi

    # Check Oh My Zsh
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        log "ERROR" "Oh My Zsh not installed"
        ((errors++))
    fi

    if [[ $errors -eq 0 ]]; then
        log "SUCCESS" "Installation validation passed"
        return 0
    else
        log "ERROR" "Installation validation failed with $errors errors"
        return 1
    fi
}

# ==========================================
# CLEANUP FUNCTIONS
# ==========================================

# Cleanup function for failed installation
cleanup_on_error() {
    log "ERROR" "Installation failed, cleaning up..."

    # Remove symlinks we created
    local files=(".zshrc" "config" ".gitignore.global")
    for file in "${files[@]}"; do
        if [[ -L "$HOME/$file" ]]; then
            rm -f "$HOME/$file"
            log "INFO" "Removed symlink: $HOME/$file"
        fi
    done

    # Restore from backup if available
    if [[ -d "$BACKUP_DIR" ]]; then
        log "INFO" "Restoring from backup..."
        for file in "$BACKUP_DIR"/*; do
            if [[ -f "$file" ]]; then
                local basename_file=$(basename "$file")
                cp "$file" "$HOME/$basename_file"
                log "INFO" "Restored: $basename_file"
            fi
        done
    fi

    log "INFO" "Cleanup completed"
}

# ==========================================
# MAIN INSTALLATION FLOW
# ==========================================

main() {
    log "INFO" "Starting secure dotfiles installation"
    log "INFO" "Installation directory: $DOTFILES_DIR"
    log "INFO" "Log file: $LOG_FILE"

    # Setup error handling
    trap cleanup_on_error ERR

    # Pre-installation checks
    check_not_root
    check_requirements
    check_existing_config
    scan_for_secrets "$HOME"

    # Get user confirmation
    echo
    log "INFO" "This script will:"
    echo "  • Install Oh My Zsh and plugins"
    echo "  • Create symlinks for dotfiles"
    echo "  • Set up secure .secrets file"
    echo "  • Configure Git with global settings"
    echo "  • Optionally install development tools"
    echo "  • Optionally set Zsh as default shell"
    echo

    read -p "Continue with installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "INFO" "Installation cancelled"
        exit 0
    fi

    # Create backup
    create_backup

    # Installation steps
    install_oh_my_zsh
    install_zsh_plugins
    symlink_files
    setup_secrets
    configure_git
    install_dev_tools
    set_default_shell

    # Validation
    if validate_installation; then
        log "SUCCESS" "Installation completed successfully!"
        echo
        log "INFO" "Next steps:"
        echo "  1. Restart your terminal or run: source ~/.zshrc"
        echo "  2. Edit ~/.secrets to add your credentials"
        echo "  3. Customize your configuration in ~/config/"
        echo "  4. Run 'env-info' to check your environment"
        echo
        log "INFO" "Backup created in: $BACKUP_DIR"
        log "INFO" "Installation log: $LOG_FILE"
    else
        log "ERROR" "Installation validation failed"
        exit 1
    fi
}

# ==========================================
# SCRIPT ENTRY POINT
# ==========================================

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi