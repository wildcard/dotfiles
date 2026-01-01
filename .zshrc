#!/usr/bin/env zsh

# ==========================================
# SECURE DOTFILES - MAIN ZSH CONFIGURATION
# ==========================================
# Security-first, modular Zsh configuration
# Author: Your Name
# Last Updated: $(date)

# Performance measurement (remove if not needed)
# zmodload zsh/zprof

# ==========================================
# SECURITY CHECKS
# ==========================================

# Ensure we're running in a secure environment
if [[ "$(id -u)" == "0" ]]; then
    echo "⚠️  WARNING: Running as root. Consider using a non-privileged user."
fi

# Check for .secrets file and warn if missing
if [[ ! -f "$HOME/.secrets" ]]; then
    echo "🔐 INFO: No .secrets file found. Create one from .secrets.template if needed."
fi

# ==========================================
# ENVIRONMENT DETECTION
# ==========================================

# Detect GitHub Codespaces
if [[ -n "${CODESPACES:-}" ]]; then
    export IS_CODESPACE=true
    export BROWSER="echo"  # Disable browser opening in Codespaces
    echo "☁️  Running in GitHub Codespaces"
fi

# ==========================================
# OH MY ZSH CONFIGURATION
# ==========================================

# Path to Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set theme (lightweight for performance)
ZSH_THEME="robbyrussell"

# Plugins for productivity and development
# Note: 1password and ssh-agent plugins are macOS-specific and excluded in Codespaces
if [[ "${IS_CODESPACE:-false}" == "true" ]]; then
    plugins=(
        git
        aws
        docker
        kubectl
        terraform
        python
        node
        z
        tmux
        zsh-autosuggestions
        zsh-syntax-highlighting
    )
else
    plugins=(
        git
        aws
        docker
        kubectl
        terraform
        python
        node
        z
        tmux
        1password
        ssh-agent
        zsh-autosuggestions
        zsh-syntax-highlighting
    )
fi

# SSH-Agent configuration
zstyle :omz:plugins:ssh-agent agent-forwarding yes
zstyle :omz:plugins:ssh-agent identities id_rsa id_ed25519

# Load Oh My Zsh
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"
else
    echo "⚠️  Oh My Zsh not found. Run the installation script first."
fi

# ==========================================
# PATH CONFIGURATION
# ==========================================

# Multi-architecture Homebrew support
if [[ -d "/opt/homebrew" ]]; then
    # Apple Silicon
    export HOMEBREW_PREFIX="/opt/homebrew"
elif [[ -d "/home/linuxbrew/.linuxbrew" ]]; then
    # Linux Homebrew (Codespaces/WSL)
    export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
elif [[ -d "/usr/local" ]]; then
    # Intel Mac or standard Linux
    export HOMEBREW_PREFIX="/usr/local"
fi

# Build PATH securely
typeset -U path  # Remove duplicates
path=(
    "$HOME/bin"
    "$HOME/.local/bin"
    "$HOMEBREW_PREFIX/bin"
    "$HOMEBREW_PREFIX/sbin"
    "/usr/local/bin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
    $path
)
export PATH

# ==========================================
# LOAD MODULAR CONFIGURATIONS
# ==========================================

# Configuration directory
DOTFILES_CONFIG="${ZDOTDIR:-$HOME}/config"

# Source modular configuration files
if [[ -d "$DOTFILES_CONFIG" ]]; then
    # Load in specific order for dependencies
    local config_files=(
        "exports.zsh"      # Environment variables first
        "functions.zsh"    # Functions before aliases
        "aliases.zsh"      # General aliases
        "aws.zsh"         # AWS-specific config
        "docker.zsh"      # Docker utilities
        "kubernetes.zsh"  # Kubernetes helpers
        "node.zsh"        # Node.js/FNM setup
        "python.zsh"      # Python/Pyenv setup
    )

    for config_file in "${config_files[@]}"; do
        if [[ -f "$DOTFILES_CONFIG/$config_file" ]]; then
            source "$DOTFILES_CONFIG/$config_file"
        fi
    done
else
    echo "⚠️  Config directory not found: $DOTFILES_CONFIG"
fi

# ==========================================
# SECURE SECRETS LOADING
# ==========================================

# Load secrets file if it exists and has secure permissions
if [[ -f "$HOME/.secrets" ]]; then
    # Check file permissions (should be 600)
    local secrets_perms=$(stat -f "%A" "$HOME/.secrets" 2>/dev/null || stat -c "%a" "$HOME/.secrets" 2>/dev/null)
    if [[ "$secrets_perms" == "600" ]]; then
        source "$HOME/.secrets"
    else
        echo "🔒 WARNING: .secrets file has insecure permissions ($secrets_perms). Should be 600."
        echo "Fix with: chmod 600 ~/.secrets"
    fi
fi

# ==========================================
# DEVELOPMENT ENVIRONMENT
# ==========================================

# Default editor
export EDITOR="code"
export VISUAL="code"

# Language and locale
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Development environment indicators
export LOCAL_RUN="true"
export ENVIRONMENT="development"
export NODE_ENV="development"

# ==========================================
# COMPLETION SYSTEM
# ==========================================

# Initialize completion system
autoload -Uz compinit

# Security: only run compinit once per day
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# ==========================================
# HISTORY CONFIGURATION
# ==========================================

# History settings
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000

# History options
setopt EXTENDED_HISTORY          # Write timestamps to history
setopt SHARE_HISTORY            # Share history between sessions
setopt APPEND_HISTORY           # Append to history file
setopt INC_APPEND_HISTORY       # Write commands immediately
setopt HIST_EXPIRE_DUPS_FIRST   # Expire duplicates first
setopt HIST_IGNORE_DUPS         # Don't record duplicates
setopt HIST_IGNORE_ALL_DUPS     # Remove older duplicates
setopt HIST_FIND_NO_DUPS        # Don't show duplicates in search
setopt HIST_IGNORE_SPACE        # Don't record commands starting with space
setopt HIST_SAVE_NO_DUPS        # Don't save duplicates
setopt HIST_REDUCE_BLANKS       # Remove superfluous blanks

# ==========================================
# PROMPT CUSTOMIZATION
# ==========================================

# Use Starship prompt if available, otherwise fallback to robbyrussell
if command -v starship &>/dev/null; then
    # Starship config location
    export STARSHIP_CONFIG="${ZDOTDIR:-$HOME}/config/starship.toml"
    eval "$(starship init zsh)"
else
    # Fallback: Add AWS profile to prompt if available
    if command -v aws &> /dev/null; then
        RPROMPT='${AWS_PROFILE:+[aws:$AWS_PROFILE]}'
    fi
fi

# ==========================================
# ZOXIDE INITIALIZATION
# ==========================================

if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi

# ==========================================
# FINAL SETUP
# ==========================================

# Load user-specific customizations
if [[ -f "$HOME/.zshrc.local" ]]; then
    source "$HOME/.zshrc.local"
fi

# Performance measurement (uncomment to debug startup time)
# zprof

# Security reminder
if [[ -n "$TMUX" ]] || [[ -n "$SSH_CONNECTION" ]]; then
    echo "🔐 Security reminder: You're in a shared/remote session. Be mindful of sensitive data."
fi