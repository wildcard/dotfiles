# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is Mathias Bynens' dotfiles repository - a collection of shell configuration files, aliases, functions, and setup scripts for macOS and Unix environments. The dotfiles are designed to enhance the command-line experience with productivity shortcuts, improved prompts, and sensible defaults.

## Key Setup Commands

### Bootstrap/Installation
```bash
# Install dotfiles (copies files to home directory)
source bootstrap.sh

# Force install without confirmation prompt
source bootstrap.sh -f
```

### macOS Setup
```bash
# Apply sensible macOS system defaults
./.macos

# Install Homebrew packages and command-line tools
./brew.sh
```

## Architecture & Structure

### Core Configuration Files
- `.bash_profile` - Main bash configuration entry point
- `.bashrc` - Bash shell configuration
- `.aliases` - Command aliases and shortcuts
- `.functions` - Custom bash functions
- `.exports` - Environment variables
- `.bash_prompt` - Custom shell prompt configuration

### Key Directories
- `bin/` - Custom executables and symlinks
- `init/` - Application configuration files (Sublime Text, iTerm, etc.)
- `.vim/` - Vim configuration and plugins

### Configuration Flow
1. `.bash_profile` sources other dotfiles in specific order
2. `.aliases` provides navigation shortcuts and command replacements
3. `.functions` adds utility functions like `mkd()` for mkdir+cd
4. `.exports` sets up PATH and environment variables
5. Optional `~/.extra` and `~/.path` files for local customizations

### Notable Features
- Cross-platform compatibility (macOS/Linux) with feature detection
- Git integration and aliases
- Enhanced `ls` with colors and formatting
- Homebrew integration for package management
- Vim configuration with custom settings
- CTF tools and security utilities via brew.sh

## Development Workflow

This repository doesn't use traditional build/test/lint commands. Instead:

1. **Testing changes**: Source files directly or run `source bootstrap.sh` to test
2. **Installation**: Use `bootstrap.sh` to sync changes to home directory
3. **macOS setup**: Run `.macos` for system preferences and `brew.sh` for packages

## Customization

- Add personal customizations to `~/.extra` (not tracked in repo)
- Override PATH in `~/.path` (sourced before feature detection)
- Fork the repository rather than modifying directly for personal use