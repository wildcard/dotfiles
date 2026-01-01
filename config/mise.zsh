#!/usr/bin/env zsh

# ==========================================
# MISE RUNTIME MANAGER
# ==========================================
# Alternative to fnm+pyenv - manages all runtimes

if command -v mise &>/dev/null; then
    eval "$(mise activate zsh)"

    # Completion
    if [[ -d "$HOMEBREW_PREFIX/share/zsh/site-functions" ]]; then
        fpath=("$HOMEBREW_PREFIX/share/zsh/site-functions" $fpath)
    fi
fi

# mise aliases
alias mi="mise install"
alias mu="mise use"
alias ml="mise list"
alias mlr="mise list-remote"
alias mup="mise upgrade"
