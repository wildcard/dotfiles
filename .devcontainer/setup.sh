#!/usr/bin/env bash
set -euo pipefail

# Detect if running in Codespaces
if [[ -n "${CODESPACES:-}" ]]; then
    echo "Running in GitHub Codespaces environment"
fi

# Install modern CLI tools via apt and cargo
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
        htop \
        cargo \
        build-essential

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

# Install Rust-based tools via cargo (not available in apt)
install_cargo_tools() {
    echo "Installing Rust-based CLI tools..."

    # zoxide (smarter cd)
    if ! command -v zoxide &>/dev/null; then
        cargo install zoxide
    fi

    # procs (better ps)
    if ! command -v procs &>/dev/null; then
        cargo install procs
    fi

    # bottom (better top/htop)
    if ! command -v btm &>/dev/null; then
        cargo install bottom
    fi

    # tealdeer (tldr pages)
    if ! command -v tldr &>/dev/null; then
        cargo install tealdeer
        # Update tldr cache
        tldr --update || true
    fi

    # hyperfine (benchmarking)
    if ! command -v hyperfine &>/dev/null; then
        cargo install hyperfine
    fi

    # sd (better sed)
    if ! command -v sd &>/dev/null; then
        cargo install sd
    fi
}

# Install GitHub CLI (official apt repo)
install_github_cli() {
    echo "Installing GitHub CLI..."
    if ! command -v gh &>/dev/null; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt-get update
        sudo apt-get install -y gh
    fi
}

# Install starship prompt
install_starship() {
    echo "Installing Starship prompt..."
    if ! command -v starship &>/dev/null; then
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi
}

# Install mise (runtime manager)
install_mise() {
    echo "Installing mise..."
    if ! command -v mise &>/dev/null; then
        curl https://mise.run | sh
        # Add mise to PATH for current session
        export PATH="$HOME/.local/bin:$PATH"
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
    install_cargo_tools
    install_github_cli
    install_starship
    install_mise
    install_zsh_plugins
    setup_dotfiles

    echo "Setup complete!"
    echo "Installed tools:"
    echo "  Core: rg, bat, fd, fzf, eza, delta, jq"
    echo "  Extended: zoxide, procs, bottom, tldr, hyperfine, sd"
    echo "  Dev: gh, starship, mise"
    echo ""
    echo "Restart your shell or run: exec zsh"
}

main "$@"
