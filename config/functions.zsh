#!/usr/bin/env zsh

# ==========================================
# SECURE DOTFILES - FUNCTIONS CONFIGURATION
# ==========================================
# Utility functions for productivity and development
# Security-focused with error handling

# ==========================================
# DIRECTORY & FILE OPERATIONS
# ==========================================

# Create directory and enter it
mkd() {
    if [[ -z "$1" ]]; then
        echo "Usage: mkd <directory_name>"
        return 1
    fi
    mkdir -p "$1" && cd "$1"
}

# Quick backup with timestamp
backup() {
    if [[ -z "$1" ]]; then
        echo "Usage: backup <file_or_directory>"
        return 1
    fi

    local item="$1"
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_name="${item}.backup_${timestamp}"

    if [[ -e "$item" ]]; then
        cp -r "$item" "$backup_name"
        echo "✅ Backup created: $backup_name"
    else
        echo "❌ Error: $item does not exist"
        return 1
    fi
}

# Universal archive extractor
extract() {
    if [[ -z "$1" ]]; then
        echo "Usage: extract <archive_file>"
        echo "Supported formats: tar.gz, tar.bz2, tar.xz, zip, rar, 7z, gz, bz2, xz"
        return 1
    fi

    if [[ ! -f "$1" ]]; then
        echo "❌ Error: File '$1' not found"
        return 1
    fi

    case "$1" in
        *.tar.gz|*.tgz)   tar -xzf "$1" ;;
        *.tar.bz2|*.tbz2) tar -xjf "$1" ;;
        *.tar.xz|*.txz)   tar -xJf "$1" ;;
        *.tar)            tar -xf "$1" ;;
        *.zip)            unzip "$1" ;;
        *.rar)            unrar x "$1" ;;
        *.7z)             7z x "$1" ;;
        *.gz)             gunzip "$1" ;;
        *.bz2)            bunzip2 "$1" ;;
        *.xz)             unxz "$1" ;;
        *.Z)              uncompress "$1" ;;
        *)
            echo "❌ Error: '$1' cannot be extracted via extract()"
            echo "Supported formats: tar.gz, tar.bz2, tar.xz, zip, rar, 7z, gz, bz2, xz"
            return 1
            ;;
    esac

    echo "✅ Extraction completed: $1"
}

# ==========================================
# GIT UTILITIES
# ==========================================

# Git cleanup: remove merged branches
git-cleanup() {
    echo "🧹 Cleaning up merged Git branches..."

    # Fetch latest changes
    git fetch --prune

    # Get current branch
    local current_branch=$(git rev-parse --abbrev-ref HEAD)
    echo "📍 Current branch: $current_branch"

    # Get merged branches (exclude main, master, develop, and current)
    local merged_branches=$(git branch --merged | grep -v -E "^\*|main|master|develop" | xargs -n 1)

    if [[ -z "$merged_branches" ]]; then
        echo "✅ No merged branches to clean up"
        return 0
    fi

    echo "🗑️  Merged branches to delete:"
    echo "$merged_branches"

    read "confirm?Delete these branches? (y/N): "
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo "$merged_branches" | xargs -n 1 git branch -d
        echo "✅ Cleanup completed"
    else
        echo "❌ Cleanup cancelled"
    fi
}

# Git push with upstream tracking
gpu() {
    local branch=$(git rev-parse --abbrev-ref HEAD)
    echo "🚀 Pushing $branch with upstream tracking..."
    git push -u origin "$branch"
}

# Git commit with conventional commits format
gccm() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: gccm <type> <message> [scope]"
        echo "Types: feat, fix, docs, style, refactor, test, chore"
        echo "Example: gccm feat 'add user authentication' auth"
        return 1
    fi

    local type="$1"
    local message="$2"
    local scope="$3"

    local commit_msg
    if [[ -n "$scope" ]]; then
        commit_msg="${type}(${scope}): ${message}"
    else
        commit_msg="${type}: ${message}"
    fi

    git commit -m "$commit_msg"
}

# ==========================================
# DEVELOPMENT ENVIRONMENT
# ==========================================

# Environment information display
env-info() {
    echo "🔍 Environment Information"
    echo "=========================="
    echo "OS: $(uname -s)"
    echo "Arch: $(uname -m)"
    echo "User: $USER"
    echo "Shell: $SHELL"
    echo "PWD: $PWD"
    echo ""

    echo "📦 Development Tools:"
    echo "===================="
    command -v git && echo "Git: $(git --version | cut -d' ' -f3)"
    command -v node && echo "Node.js: $(node --version)"
    command -v npm && echo "npm: $(npm --version)"
    command -v python3 && echo "Python: $(python3 --version | cut -d' ' -f2)"
    command -v docker && echo "Docker: $(docker --version | cut -d' ' -f3 | tr -d ',')"
    command -v kubectl && echo "kubectl: $(kubectl version --client --short | cut -d' ' -f3)"
    command -v aws && echo "AWS CLI: $(aws --version | cut -d' ' -f1 | cut -d'/' -f2)"
    echo ""

    if [[ -n "$AWS_PROFILE" ]]; then
        echo "☁️  AWS Profile: $AWS_PROFILE"
    fi

    if [[ -n "$KUBECONFIG" ]] || kubectl config current-context &>/dev/null; then
        echo "☸️  Kubernetes Context: $(kubectl config current-context 2>/dev/null || echo 'Not set')"
    fi

    echo ""
    echo "🔒 Security Status:"
    echo "=================="
    if [[ -f "$HOME/.secrets" ]]; then
        local perms=$(stat -f "%A" "$HOME/.secrets" 2>/dev/null || stat -c "%a" "$HOME/.secrets" 2>/dev/null)
        if [[ "$perms" == "600" ]]; then
            echo "✅ .secrets file permissions: $perms (secure)"
        else
            echo "⚠️  .secrets file permissions: $perms (should be 600)"
        fi
    else
        echo "ℹ️  No .secrets file found"
    fi
}

# ==========================================
# PYTHON UTILITIES
# ==========================================

# Create and activate Python virtual environment
mkvenv() {
    local venv_name="${1:-venv}"
    local python_version="${2:-python3}"

    echo "🐍 Creating virtual environment: $venv_name"

    if command -v "$python_version" &>/dev/null; then
        "$python_version" -m venv "$venv_name"
        echo "✅ Virtual environment created: $venv_name"
        echo "To activate: source $venv_name/bin/activate"
    else
        echo "❌ Python version '$python_version' not found"
        return 1
    fi
}

# Activate virtual environment (smart finder)
activate-venv() {
    local venv_dirs=("venv" ".venv" "env" ".env")
    local found=false

    for dir in "${venv_dirs[@]}"; do
        if [[ -f "$dir/bin/activate" ]]; then
            echo "🐍 Activating virtual environment: $dir"
            source "$dir/bin/activate"
            found=true
            break
        fi
    done

    if [[ "$found" == false ]]; then
        echo "❌ No virtual environment found in current directory"
        echo "Looked for: ${venv_dirs[*]}"
        return 1
    fi
}

# ==========================================
# SECURITY UTILITIES
# ==========================================

# Check for exposed secrets in files
check-secrets() {
    local target="${1:-.}"

    echo "🔍 Scanning for potential secrets in: $target"
    echo "========================================"

    # Common secret patterns
    local patterns=(
        "password.*=.*['\"][^'\"]*['\"]"
        "api[_-]?key.*=.*['\"][^'\"]*['\"]"
        "secret.*=.*['\"][^'\"]*['\"]"
        "token.*=.*['\"][^'\"]*['\"]"
        "aws[_-]?access[_-]?key"
        "aws[_-]?secret[_-]?key"
        "private[_-]?key"
        "rsa[_-]?private[_-]?key"
        "ssh[_-]?private[_-]?key"
    )

    local found_secrets=false

    for pattern in "${patterns[@]}"; do
        if command -v rg &>/dev/null; then
            local matches=$(rg -i "$pattern" "$target" --type-not binary 2>/dev/null)
        else
            local matches=$(grep -r -i "$pattern" "$target" --exclude-dir=.git 2>/dev/null)
        fi

        if [[ -n "$matches" ]]; then
            echo "⚠️  Found potential secrets matching: $pattern"
            echo "$matches"
            echo ""
            found_secrets=true
        fi
    done

    if [[ "$found_secrets" == false ]]; then
        echo "✅ No obvious secrets found"
    else
        echo "🚨 SECURITY WARNING: Potential secrets detected!"
        echo "Please review the matches above and ensure sensitive data is not exposed."
    fi
}

# Generate secure password
genpass() {
    local length="${1:-32}"
    local use_symbols="${2:-true}"

    if [[ "$use_symbols" == "true" ]]; then
        openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-"$length"
    else
        openssl rand -base64 "$length" | tr -d "=+/\[\]{}()<>|&*?!@#$%^~\`" | cut -c1-"$length"
    fi
}

# ==========================================
# NETWORK UTILITIES
# ==========================================

# Check if a port is open
port-check() {
    local host="${1:-localhost}"
    local port="$2"

    if [[ -z "$port" ]]; then
        echo "Usage: port-check [host] <port>"
        echo "Example: port-check localhost 3000"
        return 1
    fi

    if command -v nc &>/dev/null; then
        if nc -z "$host" "$port" 2>/dev/null; then
            echo "✅ Port $port is open on $host"
        else
            echo "❌ Port $port is closed on $host"
            return 1
        fi
    else
        echo "❌ netcat (nc) not available"
        return 1
    fi
}

# Find process using a port
port-process() {
    local port="$1"

    if [[ -z "$port" ]]; then
        echo "Usage: port-process <port_number>"
        return 1
    fi

    echo "🔍 Checking what's using port $port..."

    if command -v lsof &>/dev/null; then
        lsof -i ":$port"
    elif command -v netstat &>/dev/null; then
        netstat -tulpn | grep ":$port"
    else
        echo "❌ Neither lsof nor netstat available"
        return 1
    fi
}

# ==========================================
# PRODUCTIVITY UTILITIES
# ==========================================

# Quick note taking
note() {
    local note_file="$HOME/notes/$(date +%Y-%m-%d).md"
    local note_dir="$(dirname "$note_file")"

    # Create notes directory if it doesn't exist
    [[ ! -d "$note_dir" ]] && mkdir -p "$note_dir"

    if [[ $# -eq 0 ]]; then
        # Open today's note file
        "$EDITOR" "$note_file"
    else
        # Append note with timestamp
        echo "$(date +%H:%M) - $*" >> "$note_file"
        echo "✅ Note added to $note_file"
    fi
}

# Timer function
timer() {
    local duration="$1"

    if [[ -z "$duration" ]]; then
        echo "Usage: timer <duration>"
        echo "Examples: timer 5m, timer 30s, timer 1h"
        return 1
    fi

    echo "⏰ Timer started for $duration"
    sleep "$duration"
    echo "⏰ Timer finished! ($duration)"

    # Try to send notification if available
    if command -v osascript &>/dev/null; then
        # macOS notification
        osascript -e "display notification \"Timer finished!\" with title \"$duration Timer\""
    elif command -v notify-send &>/dev/null; then
        # Linux notification
        notify-send "Timer" "Timer finished! ($duration)"
    fi
}

# Weather function (requires curl)
weather() {
    local location="${1:-}"
    if [[ -n "$location" ]]; then
        curl -s "wttr.in/$location?format=3"
    else
        curl -s "wttr.in/?format=3"
    fi
}

# ==========================================
# FILE OPERATIONS
# ==========================================

# Find and replace in files
find-replace() {
    local search="$1"
    local replace="$2"
    local target="${3:-.}"

    if [[ -z "$search" ]] || [[ -z "$replace" ]]; then
        echo "Usage: find-replace <search_pattern> <replace_pattern> [target_directory]"
        return 1
    fi

    echo "🔍 Finding and replacing in: $target"
    echo "Search: $search"
    echo "Replace: $replace"
    echo ""

    read "confirm?Proceed with replacement? (y/N): "
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        if command -v rg &>/dev/null && command -v sd &>/dev/null; then
            # Use ripgrep and sd for fast replacement
            rg -l "$search" "$target" | xargs sd "$search" "$replace"
        else
            # Fallback to find and sed
            find "$target" -type f -name "*.txt" -o -name "*.md" -o -name "*.js" -o -name "*.py" -o -name "*.sh" | \
                xargs sed -i.bak "s/$search/$replace/g"
        fi
        echo "✅ Replacement completed"
    else
        echo "❌ Replacement cancelled"
    fi
}

# ==========================================
# SYSTEM UTILITIES
# ==========================================

# Clean system caches
clean-cache() {
    echo "🧹 Cleaning system caches..."

    # macOS specific
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sudo dscacheutil -flushcache
        sudo killall -HUP mDNSResponder
        echo "✅ DNS cache cleared"
    fi

    # Clear user caches
    if [[ -d "$HOME/Library/Caches" ]]; then
        find "$HOME/Library/Caches" -name "*" -type d -exec rm -rf {} + 2>/dev/null
        echo "✅ User caches cleared"
    fi

    # Clear npm cache
    if command -v npm &>/dev/null; then
        npm cache clean --force
        echo "✅ npm cache cleared"
    fi

    # Clear yarn cache
    if command -v yarn &>/dev/null; then
        yarn cache clean
        echo "✅ Yarn cache cleared"
    fi

    echo "✅ Cache cleanup completed"
}

# System update function
system-update() {
    echo "🔄 Updating system packages..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS with Homebrew
        if command -v brew &>/dev/null; then
            brew update
            brew upgrade
            brew cleanup
            echo "✅ Homebrew packages updated"
        fi

        # Mac App Store updates
        if command -v mas &>/dev/null; then
            mas upgrade
            echo "✅ Mac App Store apps updated"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux (Ubuntu/Debian)
        if command -v apt &>/dev/null; then
            sudo apt update
            sudo apt upgrade -y
            sudo apt autoremove -y
            echo "✅ APT packages updated"
        fi
    fi

    # Update npm global packages
    if command -v npm &>/dev/null; then
        npm update -g
        echo "✅ npm global packages updated"
    fi

    echo "✅ System update completed"
}