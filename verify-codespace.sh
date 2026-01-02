#!/bin/bash
# Codespace Tools Verification Script
# Run this in the Codespace terminal to verify all tools are installed

echo "=========================================="
echo "🧪 Dotfiles Codespace Verification"
echo "=========================================="
echo

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_tool() {
    local tool=$1
    local command=${2:-$1}

    if command -v "$command" &>/dev/null; then
        version=$($command --version 2>&1 | head -n1)
        echo -e "${GREEN}✓${NC} $tool: $version"
        return 0
    else
        echo -e "${RED}✗${NC} $tool: NOT FOUND"
        return 1
    fi
}

echo "📦 Core Modern CLI Tools"
echo "---"
check_tool "ripgrep" "rg"
check_tool "bat"
check_tool "fd"
check_tool "fzf"
check_tool "eza"
check_tool "git-delta" "delta"
check_tool "jq"
check_tool "httpie" "http"
echo

echo "🦀 Rust-based Tools (cargo installs)"
echo "---"
check_tool "zoxide"
check_tool "procs"
check_tool "bottom" "btm"
check_tool "tldr"
check_tool "hyperfine"
check_tool "sd"
echo

echo "🚀 Additional Tools"
echo "---"
check_tool "GitHub CLI" "gh"
check_tool "Starship" "starship"
check_tool "mise"
echo

echo "🐚 Shell Configuration"
echo "---"
if [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
    echo -e "${GREEN}✓${NC} Default shell: zsh"
else
    echo -e "${YELLOW}⚠${NC} Default shell: $SHELL (expected zsh)"
fi

if [ -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${GREEN}✓${NC} Oh My Zsh: installed"
else
    echo -e "${RED}✗${NC} Oh My Zsh: NOT FOUND"
fi

if [ -n "$CODESPACES" ]; then
    echo -e "${GREEN}✓${NC} Running in GitHub Codespaces"
else
    echo -e "${YELLOW}⚠${NC} Not running in Codespaces"
fi
echo

echo "🔗 Aliases Test"
echo "---"
# Test if ls uses eza
if alias ls 2>/dev/null | grep -q "eza"; then
    echo -e "${GREEN}✓${NC} ls alias: using eza"
else
    echo -e "${YELLOW}⚠${NC} ls alias: not configured"
fi

# Test if cat uses bat
if alias cat 2>/dev/null | grep -q "bat"; then
    echo -e "${GREEN}✓${NC} cat alias: using bat"
else
    echo -e "${YELLOW}⚠${NC} cat alias: not configured"
fi
echo

echo "📁 Dotfiles"
echo "---"
if [ -f "$HOME/.zshrc" ]; then
    echo -e "${GREEN}✓${NC} .zshrc: exists"
else
    echo -e "${RED}✗${NC} .zshrc: NOT FOUND"
fi

if [ -f "$HOME/.gitconfig" ]; then
    echo -e "${GREEN}✓${NC} .gitconfig: exists"
else
    echo -e "${RED}✗${NC} .gitconfig: NOT FOUND"
fi
echo

echo "=========================================="
echo "✨ Verification Complete!"
echo "=========================================="
echo
echo "Next steps:"
echo "1. Test ripgrep:  rg 'TODO' ."
echo "2. Test bat:      bat README.md"
echo "3. Test eza:      eza -la"
echo "4. Test delta:    git diff"
echo "5. Test fzf:      fzf"
echo
