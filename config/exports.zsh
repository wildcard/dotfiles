#!/usr/bin/env zsh

# ==========================================
# SECURE DOTFILES - EXPORTS CONFIGURATION
# ==========================================
# Environment variables and exports
# Secure defaults with performance optimization

# ==========================================
# LANGUAGE & LOCALE
# ==========================================

export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

# ==========================================
# EDITOR CONFIGURATION
# ==========================================

# Default editor (VS Code with fallbacks)
if command -v code &> /dev/null; then
    export EDITOR="code -w"
    export VISUAL="code -w"
elif command -v vim &> /dev/null; then
    export EDITOR="vim"
    export VISUAL="vim"
else
    export EDITOR="nano"
    export VISUAL="nano"
fi

# Git editor (for commit messages)
export GIT_EDITOR="$EDITOR"

# ==========================================
# DEVELOPMENT ENVIRONMENT
# ==========================================

# Environment indicators
export LOCAL_RUN="true"
export ENVIRONMENT="development"
export NODE_ENV="development"

# Development ports (customize as needed)
export DEV_PORT="3000"
export API_PORT="8000"
export DB_PORT="5432"

# API base URLs for local development
export LOCAL_API_BASE_URL="http://localhost:${API_PORT}"
export DEV_API_BASE_URL="https://api-dev.yourdomain.com"
export STAGING_API_BASE_URL="https://api-staging.yourdomain.com"
export PROD_API_BASE_URL="https://api.yourdomain.com"

# ==========================================
# HOMEBREW CONFIGURATION
# ==========================================

# Multi-architecture Homebrew support
if [[ -d "/opt/homebrew" ]]; then
    # Apple Silicon
    export HOMEBREW_PREFIX="/opt/homebrew"
    export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
    export HOMEBREW_REPOSITORY="/opt/homebrew"
elif [[ -d "/usr/local" ]]; then
    # Intel
    export HOMEBREW_PREFIX="/usr/local"
    export HOMEBREW_CELLAR="/usr/local/Cellar"
    export HOMEBREW_REPOSITORY="/usr/local/Homebrew"
fi

# Homebrew settings
export HOMEBREW_NO_ANALYTICS=1          # Disable analytics
export HOMEBREW_NO_AUTO_UPDATE=1        # Disable auto-update
export HOMEBREW_NO_INSTALL_CLEANUP=1    # Keep old versions

# ==========================================
# NODE.JS CONFIGURATION
# ==========================================

# Node.js settings
export NODE_OPTIONS="--max-old-space-size=4096"  # Increase memory limit
export NODE_REPL_HISTORY="$HOME/.node_history"   # Persistent REPL history
export NODE_REPL_HISTORY_SIZE="32768"            # History size

# npm configuration
export NPM_CONFIG_INIT_AUTHOR_NAME="Your Name"
export NPM_CONFIG_INIT_AUTHOR_EMAIL="your.email@example.com"
export NPM_CONFIG_INIT_LICENSE="MIT"
export NPM_CONFIG_SAVE_EXACT=true               # Save exact versions

# ==========================================
# PYTHON CONFIGURATION
# ==========================================

# Python settings
export PYTHONDONTWRITEBYTECODE=1        # Don't create .pyc files
export PYTHONUNBUFFERED=1              # Unbuffered output
export PYTHONIOENCODING="utf-8"        # UTF-8 encoding

# Python path for user packages
export PYTHONPATH="${PYTHONPATH}:$HOME/.local/lib/python3.11/site-packages"

# Virtual environment settings
export VIRTUAL_ENV_DISABLE_PROMPT=1    # Don't modify prompt (we handle it)
export PIPENV_VENV_IN_PROJECT=1        # Create .venv in project directory

# ==========================================
# GO CONFIGURATION
# ==========================================

# Go settings (if using Go)
if command -v go &> /dev/null; then
    export GOPATH="$HOME/go"
    export GOBIN="$GOPATH/bin"
    export GO111MODULE="on"
fi

# ==========================================
# RUST CONFIGURATION
# ==========================================

# Rust settings (if using Rust)
if [[ -d "$HOME/.cargo" ]]; then
    export CARGO_HOME="$HOME/.cargo"
    export RUSTUP_HOME="$HOME/.rustup"
fi

# ==========================================
# JAVA CONFIGURATION
# ==========================================

# Java settings (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    if [[ -x /usr/libexec/java_home ]]; then
        export JAVA_HOME="$(/usr/libexec/java_home)"
    fi
fi

# ==========================================
# DATABASE CONFIGURATION
# ==========================================

# PostgreSQL
export PGDATA="$HOMEBREW_PREFIX/var/postgres"
export POSTGRES_DB="development"
export POSTGRES_USER="$USER"

# MySQL
export MYSQL_PS1="mysql> "

# ==========================================
# CLOUD CONFIGURATION
# ==========================================

# AWS CLI
export AWS_DEFAULT_OUTPUT="json"
export AWS_CLI_AUTO_PROMPT="on-partial"
export AWS_PAGER=""                     # Disable paging

# Docker
export DOCKER_BUILDKIT=1               # Enable BuildKit
export COMPOSE_DOCKER_CLI_BUILD=1      # Use Docker CLI for builds

# Kubernetes
export KUBE_EDITOR="$EDITOR"
export KUBECTL_EXTERNAL_DIFF="code --diff"

# ==========================================
# SECURITY CONFIGURATION
# ==========================================

# GPG settings
export GPG_TTY="$(tty)"
if [[ -n "$SSH_CONNECTION" ]]; then
    export PINENTRY_USER_DATA="USE_CURSES=1"
fi

# SSH settings
export SSH_KEY_PATH="$HOME/.ssh/id_rsa"

# 1Password CLI (if using)
if command -v op &> /dev/null; then
    export OP_BIOMETRIC_UNLOCK_ENABLED=true
fi

# ==========================================
# HISTORY CONFIGURATION
# ==========================================

# Zsh history
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=50000
export SAVEHIST=50000

# Less pager configuration
export LESS="-R -i -w -M -z-4"
export LESSHISTFILE="$HOME/.lesshst"

# ==========================================
# TERMINAL CONFIGURATION
# ==========================================

# Colors for ls (GNU coreutils)
export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'

# Colors for grep
export GREP_COLOR='1;32'
export GREP_OPTIONS='--color=auto'

# Terminal capabilities
export TERM="xterm-256color"

# ==========================================
# PERFORMANCE OPTIMIZATION
# ==========================================

# Reduce startup time
export DISABLE_AUTO_TITLE="true"
export DISABLE_UPDATE_PROMPT="true"

# Cache directories
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"

# ==========================================
# TMUX CONFIGURATION
# ==========================================

# Tmux settings
export TMUX_TMPDIR="$HOME/.tmux/tmp"

# ==========================================
# FZF CONFIGURATION
# ==========================================

# FZF settings (if installed)
if command -v fzf &> /dev/null; then
    export FZF_DEFAULT_OPTS="--height 40% --border --layout=reverse --info=inline"

    # Use fd for file/directory finding if available
    if command -v fd &> /dev/null; then
        export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND="fd --type d --hidden --follow --exclude .git"
    fi

    # Use bat for file preview if available
    if command -v bat &> /dev/null; then
        export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {}'"
        export FZF_ALT_C_OPTS="--preview 'eza -T --icons --level=2 {} 2>/dev/null || ls -la {}'"
    fi
fi

# ==========================================
# BAT CONFIGURATION
# ==========================================

# bat (modern cat with syntax highlighting)
if command -v bat &> /dev/null; then
    export BAT_THEME="Solarized (dark)"
    export BAT_STYLE="numbers,changes,header"
    export BAT_PAGER="less -RF"
fi

# ==========================================
# DELTA CONFIGURATION
# ==========================================

# delta (better git diff viewer)
if command -v delta &> /dev/null; then
    export DELTA_PAGER="less -R"
fi

# ==========================================
# RIPGREP CONFIGURATION
# ==========================================

# Ripgrep settings (if installed)
if command -v rg &> /dev/null; then
    export RIPGREP_CONFIG_PATH="$HOME/.ripgreprc"
fi

# ==========================================
# ZOXIDE CONFIGURATION
# ==========================================

# Initialize zoxide (smarter cd replacement)
if command -v zoxide &> /dev/null; then
    eval "$(zoxide init zsh)"
fi

# ==========================================
# STARSHIP CONFIGURATION
# ==========================================

# Initialize starship prompt (if installed)
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi

# ==========================================
# MISE CONFIGURATION
# ==========================================

# Initialize mise (runtime manager)
if command -v mise &> /dev/null; then
    eval "$(mise activate zsh)"
fi

# ==========================================
# APPLICATION SPECIFIC
# ==========================================

# Chrome/Chromium
export CHROME_EXECUTABLE="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# Sublime Text
export SUBL_EXECUTABLE="/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl"

# ==========================================
# CUSTOM PATHS
# ==========================================

# Add custom bin directories to PATH
typeset -U path  # Ensure unique entries
path=(
    "$HOME/bin"
    "$HOME/.local/bin"
    "$HOMEBREW_PREFIX/bin"
    "$HOMEBREW_PREFIX/sbin"
    "$HOME/.cargo/bin"     # Rust
    "$GOBIN"              # Go
    "$HOME/go/bin"        # Go binaries
    "/usr/local/bin"
    $path
)

# Add man pages
if [[ -n "$HOMEBREW_PREFIX" ]]; then
    export MANPATH="$HOMEBREW_PREFIX/share/man:$MANPATH"
fi

# ==========================================
# CONDITIONAL EXPORTS
# ==========================================

# macOS specific
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Silence macOS Bash deprecation warning
    export BASH_SILENCE_DEPRECATION_WARNING=1

    # macOS-specific paths
    export BROWSER="open"
fi

# Linux specific
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    export BROWSER="xdg-open"
fi

# WSL specific
if [[ -n "$WSL_DISTRO_NAME" ]]; then
    export BROWSER="wslview"
    export DISPLAY="$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0"
fi

# Codespaces specific
if [[ -n "$CODESPACES" ]]; then
    export BROWSER="echo"  # Disable browser opening
    export IS_CODESPACE=true
fi

# ==========================================
# LOAD ADDITIONAL EXPORTS
# ==========================================

# Load machine-specific exports if they exist
if [[ -f "$HOME/.exports.local" ]]; then
    source "$HOME/.exports.local"
fi