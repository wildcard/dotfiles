#!/usr/bin/env bash
set -euo pipefail

# Detect if running in Codespaces
if [[ -n "${CODESPACES:-}" ]]; then
    echo "Running in GitHub Codespaces environment"
fi

# Install modern CLI tools via apt
install_apt_packages() {
    echo "Installing apt packages..."
    sudo apt-get update
    sudo apt-get install -y \
        ripgrep \
        bat \
        fd-find \
        fzf \
        git-delta \
        zsh \
        curl \
        wget \
        unzip \
        jq \
        tree \
        htop

    # Create symlinks for tools with different binary names on Debian/Ubuntu
    # fd is named fdfind on Debian/Ubuntu
    if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
        sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
    fi

    # bat is named batcat on Debian/Ubuntu
    if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
        sudo ln -sf "$(which batcat)" /usr/local/bin/bat
    fi
}

# Install eza (not available in apt, install from GitHub releases)
install_eza() {
    echo "Installing eza..."
    if command -v eza &>/dev/null; then
        echo "eza already installed"
        return 0
    fi

    local EZA_VERSION="v0.18.0"
    local ARCH=$(uname -m)

    case "$ARCH" in
        x86_64) ARCH="x86_64" ;;
        aarch64|arm64) ARCH="aarch64" ;;
        *) echo "Unsupported architecture: $ARCH"; return 1 ;;
    esac

    curl -sL "https://github.com/eza-community/eza/releases/download/${EZA_VERSION}/eza_${ARCH}-unknown-linux-gnu.tar.gz" | \
        sudo tar xz -C /usr/local/bin
}

# Install Oh My Zsh plugins
install_zsh_plugins() {
    echo "Installing Zsh plugins..."
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # zsh-autosuggestions
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions \
            "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    fi

    # zsh-syntax-highlighting
    if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting \
            "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    fi
}

# Setup dotfiles
setup_dotfiles() {
    echo "Setting up dotfiles..."
    local DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

    # Create symlinks
    ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
    ln -sf "$DOTFILES_DIR/config" "$HOME/config"
    ln -sf "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
    ln -sf "$DOTFILES_DIR/.gitignore.global" "$HOME/.gitignore.global"
    ln -sf "$DOTFILES_DIR/.ripgreprc" "$HOME/.ripgreprc"

    # Setup git global ignore
    git config --global core.excludesfile "$HOME/.gitignore.global"
}

# Main execution
main() {
    echo "Setting up development environment..."

    install_apt_packages
    install_eza
    install_zsh_plugins
    setup_dotfiles

    echo "Setup complete!"
    echo "Restart your shell or run: exec zsh"
}

main "$@"
