#!/usr/bin/env zsh

# ==========================================
# SECURE DOTFILES - ALIASES CONFIGURATION
# ==========================================
# Productivity aliases for Git, Docker, Kubernetes, AWS, and more
# Security-focused with built-in safeguards

# ==========================================
# NAVIGATION & FILE OPERATIONS
# ==========================================

# Safe navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."
alias ~="cd ~"
alias -- -="cd -"

# Enhanced ls with colors and safety
if ls --color &> /dev/null; then
    # GNU ls
    alias ls="ls --color=auto"
    alias l="ls -lF --color=auto"
    alias la="ls -laF --color=auto"
    alias ll="ls -l --color=auto"
else
    # BSD ls (macOS)
    alias ls="ls -G"
    alias l="ls -lFG"
    alias la="ls -laFG"
    alias ll="ls -lG"
fi

# ==========================================
# MODERN CLI TOOLS (with smart fallbacks)
# ==========================================

# eza (modern ls replacement)
if command -v eza &>/dev/null; then
    alias ls="eza --icons --group-directories-first"
    alias l="eza -l --icons --group-directories-first"
    alias la="eza -la --icons --group-directories-first"
    alias ll="eza -l --icons --group-directories-first"
    alias lt="eza --tree --level=2 --icons"
    alias lta="eza --tree --level=2 --icons -a"
fi

# bat (better cat with syntax highlighting)
if command -v bat &>/dev/null; then
    alias cat="bat --paging=never"
    alias catp="bat"  # with pager
    alias catl="bat --style=plain"  # plain output
fi

# fd (faster find)
if command -v fd &>/dev/null; then
    alias find="fd"
    alias ffind="/usr/bin/find"  # fallback to real find
fi

# procs (better ps)
if command -v procs &>/dev/null; then
    alias pss="procs"
    alias pst="procs --tree"
fi

# bottom (better top/htop)
if command -v btm &>/dev/null; then
    alias top="btm"
    alias htop="btm"
fi

# zoxide (smarter cd)
if command -v zoxide &>/dev/null; then
    alias cd="z"
    alias cdi="zi"  # interactive
fi

# ripgrep aliases (already installed)
if command -v rg &>/dev/null; then
    alias grep="rg"
    alias rgi="rg -i"  # case insensitive
    alias rgf="rg --files | rg"  # search filenames
fi

# tealdeer/tldr (simplified man pages)
if command -v tldr &>/dev/null; then
    alias help="tldr"
fi

# Directory shortcuts (customize these for your setup)
alias dl="cd ~/Downloads"
alias dt="cd ~/Desktop"
alias dev="cd ~/Development"
alias proj="cd ~/Projects"

# File operations with safety
alias cp="cp -i"          # Prompt before overwrite
alias mv="mv -i"          # Prompt before overwrite
alias rm="rm -i"          # Prompt before delete
alias mkdir="mkdir -p"    # Create parent directories

# ==========================================
# GIT ALIASES
# ==========================================

# Basic Git operations
alias g="git"
alias gs="git status"
alias ga="git add"
alias gaa="git add ."
alias gc="git commit"
alias gcm="git commit -m"
alias gca="git commit -am"
alias gp="git push"
alias gpu="git push -u origin"
alias gl="git pull"
alias gf="git fetch"

# Git branch operations
alias gb="git branch"
alias gba="git branch -a"
alias gbd="git branch -d"
alias gbD="git branch -D"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gcm="git checkout main || git checkout master"
alias gcd="git checkout develop"

# Git log and diff
alias glog="git log --oneline --graph --decorate"
alias glogp="git log --oneline --graph --decorate --all"
alias gd="git diff"
alias gdc="git diff --cached"
alias gdh="git diff HEAD"

# Git status and information
alias gst="git status -sb"
alias gwho="git shortlog -sn"
alias gwhat="git log --stat --oneline"

# Git stash operations
alias gstash="git stash"
alias gstashp="git stash pop"
alias gstashl="git stash list"

# Git remote operations
alias gr="git remote"
alias grv="git remote -v"
alias gra="git remote add"
alias grr="git remote remove"

# ==========================================
# GITHUB CLI ALIASES
# ==========================================

if command -v gh &>/dev/null; then
    # PR management
    alias ghpr="gh pr list"
    alias ghprc="gh pr create"
    alias ghprv="gh pr view"
    alias ghprco="gh pr checkout"
    alias ghprm="gh pr merge"

    # Issue management
    alias ghi="gh issue list"
    alias ghic="gh issue create"
    alias ghiv="gh issue view"

    # Repo management
    alias ghrc="gh repo clone"
    alias ghrv="gh repo view -w"

    # Actions
    alias gha="gh run list"
    alias ghaw="gh run watch"
fi

# ==========================================
# DOCKER ALIASES
# ==========================================

# Docker basics
alias d="docker"
alias dc="docker-compose"
alias dcu="docker-compose up"
alias dcd="docker-compose down"
alias dcb="docker-compose build"
alias dcr="docker-compose restart"

# Docker containers
alias dps="docker ps"
alias dpsa="docker ps -a"
alias di="docker images"
alias drmi="docker rmi"
alias drm="docker rm"

# Docker system operations
alias dprune="docker system prune"
alias dprunea="docker system prune -a"
alias dvprune="docker volume prune"
alias dnprune="docker network prune"

# Docker logs and exec
alias dlogs="docker logs"
alias dlogf="docker logs -f"
alias dexec="docker exec -it"
alias dsh="docker exec -it"

# ==========================================
# KUBERNETES ALIASES
# ==========================================

# kubectl basics
alias k="kubectl"
alias kgp="kubectl get pods"
alias kgs="kubectl get services"
alias kgd="kubectl get deployments"
alias kgn="kubectl get nodes"
alias kga="kubectl get all"

# kubectl describe
alias kdp="kubectl describe pod"
alias kds="kubectl describe service"
alias kdd="kubectl describe deployment"

# kubectl logs and exec
alias klog="kubectl logs"
alias klogf="kubectl logs -f"
alias kexec="kubectl exec -it"
alias ksh="kubectl exec -it"

# kubectl apply and delete
alias ka="kubectl apply -f"
alias kdel="kubectl delete"
alias kdelp="kubectl delete pod"

# Namespace operations
alias kns="kubectl config set-context --current --namespace"
alias kgns="kubectl get namespaces"

# Context operations
alias kctx="kubectl config current-context"
alias kctxs="kubectl config get-contexts"
alias kuse="kubectl config use-context"

# ==========================================
# AWS ALIASES
# ==========================================

# AWS CLI basics
alias aws-whoami="aws sts get-caller-identity"
alias aws-regions="aws ec2 describe-regions --query 'Regions[].RegionName' --output table"

# AWS profile management (enhanced by aws.zsh)
alias awsp="aws-switch"
alias awsprofiles="aws configure list-profiles"

# S3 operations
alias s3ls="aws s3 ls"
alias s3sync="aws s3 sync"
alias s3cp="aws s3 cp"

# EC2 operations
alias ec2-instances="aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,State.Name,InstanceType,Tags[?Key==\`Name\`].Value|[0]]' --output table"

# ==========================================
# PYTHON ALIASES
# ==========================================

# Python virtual environments
alias venv="python -m venv"
alias activate="source venv/bin/activate"
alias deactivate="deactivate"

# Python package management
alias pip-upgrade="pip install --upgrade pip"
alias pip-freeze="pip freeze > requirements.txt"
alias pip-install-req="pip install -r requirements.txt"

# Python utilities
alias py="python"
alias py3="python3"
alias ipy="ipython"
alias jnb="jupyter notebook"
alias jlab="jupyter lab"

# ==========================================
# NODE.JS ALIASES
# ==========================================

# npm operations
alias ni="npm install"
alias nid="npm install --save-dev"
alias nig="npm install -g"
alias nr="npm run"
alias ns="npm start"
alias nt="npm test"
alias nb="npm run build"

# yarn operations
alias y="yarn"
alias ya="yarn add"
alias yad="yarn add --dev"
alias yr="yarn run"
alias ys="yarn start"
alias yt="yarn test"
alias yb="yarn build"

# Package.json utilities
alias nls="npm list --depth=0"
alias nout="npm outdated"

# ==========================================
# SYSTEM & NETWORK ALIASES
# ==========================================

# System information
alias myip="curl -s ipinfo.io/ip"
alias localip="ipconfig getifaddr en0 || hostname -I | cut -d' ' -f1"
alias ports="lsof -i -P -n | grep LISTEN"
alias listening="lsof -i -P -n | grep LISTEN"

# Process management
alias psg="ps aux | grep"
alias top="htop"
alias cpu="top -o cpu"
alias mem="top -o rsize"

# Network utilities
alias ping="ping -c 5"
alias wget="wget -c"
alias curl-time="curl -w '@-' -o /dev/null -s"

# ==========================================
# SECURITY & CLEANUP ALIASES
# ==========================================

# Secure file operations
alias shred="shred -vfz -n 3"  # Secure file deletion
alias secure-rm="rm -P"       # macOS secure delete

# Cleanup operations
alias cleanup-ds="find . -name '.DS_Store' -type f -delete"
alias cleanup-logs="sudo rm -rf /private/var/log/*.log"
alias cleanup-cache="rm -rf ~/Library/Caches/*"

# Security checks
alias check-ports="nmap -sT -O localhost"
alias check-listening="netstat -tuln"

# ==========================================
# DEVELOPMENT SHORTCUTS
# ==========================================

# Code editors
alias c="code"
alias c.="code ."
alias subl="open -a 'Sublime Text'"
alias vim="nvim"

# Quick servers
alias http-server="python -m http.server 8000"
alias php-server="php -S localhost:8000"

# Database shortcuts
alias postgres-start="brew services start postgresql"
alias postgres-stop="brew services stop postgresql"
alias mysql-start="brew services start mysql"
alias mysql-stop="brew services stop mysql"

# ==========================================
# TMUX ALIASES
# ==========================================

alias t="tmux"
alias ta="tmux attach"
alias tls="tmux list-sessions"
alias tnew="tmux new-session -s"
alias tkill="tmux kill-session -t"

# ==========================================
# UTILITY ALIASES
# ==========================================

# Quick edits
alias zshrc="$EDITOR ~/.zshrc"
alias aliases="$EDITOR $DOTFILES_CONFIG/aliases.zsh"
alias functions="$EDITOR $DOTFILES_CONFIG/functions.zsh"
alias exports="$EDITOR $DOTFILES_CONFIG/exports.zsh"

# Reload shell
alias reload="source ~/.zshrc"
alias re="source ~/.zshrc"

# Date and time
alias now="date +'%Y-%m-%d %H:%M:%S'"
alias nowutc="date -u +'%Y-%m-%d %H:%M:%S UTC'"
alias timestamp="date +%s"

# Archive operations
alias tar-create="tar -czf"
alias tar-extract="tar -xzf"
alias tar-list="tar -tzf"

# ==========================================
# CONDITIONAL ALIASES
# ==========================================

# macOS specific
if [[ "$OSTYPE" == "darwin"* ]]; then
    alias flushdns="sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder"
    alias show-hidden="defaults write com.apple.finder AppleShowAllFiles -bool true && killall Finder"
    alias hide-hidden="defaults write com.apple.finder AppleShowAllFiles -bool false && killall Finder"
    alias lock="pmset displaysleepnow"
fi

# Linux specific
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    alias flushdns="sudo systemctl restart systemd-resolved"
    alias update="sudo apt update && sudo apt upgrade"
    alias install="sudo apt install"
fi

# ==========================================
# MODERN CLI TOOL ALIASES
# ==========================================

# eza (modern ls replacement with git integration)
if command -v eza &>/dev/null; then
    alias ls="eza --icons --group-directories-first"
    alias l="eza -l --icons --group-directories-first"
    alias la="eza -la --icons --group-directories-first"
    alias ll="eza -l --icons --group-directories-first"
    alias lt="eza -T --icons --level=2"  # Tree view 2 levels deep
    alias lta="eza -Ta --icons --level=2 --git-ignore"  # Tree with hidden files
    alias lg="eza -l --icons --group-directories-first --git"  # Show git status
fi

# bat (modern cat with syntax highlighting)
if command -v bat &>/dev/null; then
    alias cat="bat --paging=never"
    alias catp="bat"  # cat with paging
    alias bathelp="bat --plain --language=help"
    # Use bat for man pages with syntax highlighting
    export MANPAGER="sh -c 'col -bx | bat -l man -p'"
    export MANROFFOPT="-c"
fi

# fd (modern find replacement)
if command -v fd &>/dev/null; then
    alias find="fd"
fi

# ripgrep (fast grep replacement)
if command -v rg &>/dev/null; then
    alias grep="rg"
    alias rgi="rg -i"  # Case insensitive search
    alias rgf="rg --files"  # Just list files that would be searched
    alias rgl="rg --files-with-matches"  # List files containing matches
fi

# delta (better git diff)
if command -v delta &>/dev/null; then
    alias diff="delta"
fi

# httpie (user-friendly HTTP client)
if command -v http &>/dev/null; then
    alias curl="http"  # Replace curl with httpie for better UX
    alias https="https"  # HTTPS variant
fi

# ==========================================
# SAFETY OVERRIDES
# ==========================================

# Prevent dangerous operations
alias rm="rm -i"
alias mv="mv -i"
alias cp="cp -i"

# Add confirmation for destructive Git operations
alias git-reset-hard="echo 'Are you sure? This will lose uncommitted changes. Use: git reset --hard'"
alias git-clean-force="echo 'Are you sure? This will delete untracked files. Use: git clean -fd'"

# Add safety to Docker cleanup
alias docker-nuke="echo 'This will remove ALL containers, images, and volumes! Use docker-cleanup function instead.'"