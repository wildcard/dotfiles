# 🔐 Secure Dotfiles

A comprehensive, security-first dotfiles configuration for modern development workflows. Built with Zsh, Oh My Zsh, and modular architecture for maximum productivity and security.

## ⚡ Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/dotfiles.git
cd dotfiles

# Run the secure installation script
./install.sh
```

## 🛡️ Security Features

- **Secrets Management**: Secure `.secrets` file with 600 permissions
- **Secret Detection**: Built-in scanning for exposed credentials
- **Secure Defaults**: Safe aliases and functions with confirmations
- **Permission Validation**: Automatic file permission checks
- **No Root Execution**: Prevents running as root for security

## 📁 Architecture

```
dotfiles/
├── .zshrc                    # Main Zsh configuration
├── .secrets.template         # Template for secure secrets
├── .gitignore.global        # Global Git ignore patterns
├── install.sh               # Secure installation script
├── config/                  # Modular configuration
│   ├── aliases.zsh          # Git, Docker, K8s, AWS shortcuts
│   ├── exports.zsh          # Environment variables
│   ├── functions.zsh        # Utility functions
│   ├── aws.zsh             # AWS profile management
│   ├── docker.zsh          # Docker utilities
│   ├── kubernetes.zsh      # Kubernetes helpers
│   ├── node.zsh            # Node.js/FNM management
│   └── python.zsh          # Python/Pyenv setup
└── README.md               # This file
```

## 🔧 Features

### Development Tools Integration

- **Oh My Zsh**: Powerful framework with curated plugins
- **FNM**: Fast Node.js version management with auto-switching
- **Pyenv**: Python version management with OpenSSL configuration
- **AWS CLI**: Interactive profile switching and utilities
- **Docker**: Comprehensive cleanup and management tools
- **Kubernetes**: Context switching and debugging helpers

### Productivity Enhancements

- **Smart Aliases**: Git shortcuts, Docker commands, K8s operations
- **Utility Functions**: Backup, extract, environment info, security checks
- **Cross-Platform**: macOS, Linux, and cloud environment support
- **Performance Optimized**: Lazy loading and efficient startup

### Security Features

- **Secret Scanning**: Detect exposed credentials in files
- **Secure Permissions**: Automatic validation and fixing
- **Safe Operations**: Confirmations for destructive commands
- **Environment Isolation**: Separate configs for different environments

## 📦 Installation

### Prerequisites

- Git
- Curl
- A Unix-like operating system (macOS, Linux, WSL)

### Automatic Installation

The installation script will:

1. Check system requirements and security
2. Backup existing configuration files
3. Install Oh My Zsh and plugins
4. Create secure symlinks for dotfiles
5. Set up `.secrets` file with proper permissions
6. Configure Git with global settings
7. Optionally install development tools (FNM, Pyenv)
8. Optionally set Zsh as default shell

```bash
./install.sh
```

### Manual Installation

If you prefer manual setup:

```bash
# 1. Install Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# 2. Install Zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# 3. Symlink configuration files
ln -sf "$PWD/.zshrc" ~/.zshrc
ln -sf "$PWD/config" ~/config
ln -sf "$PWD/.gitignore.global" ~/.gitignore.global

# 4. Set up secrets file
cp .secrets.template ~/.secrets
chmod 600 ~/.secrets

# 5. Configure Git
git config --global core.excludesfile ~/.gitignore.global

# 6. Reload shell
source ~/.zshrc
```

## 🔐 Secrets Management

### Setting Up Secrets

1. Copy the template:
   ```bash
   cp .secrets.template ~/.secrets
   chmod 600 ~/.secrets
   ```

2. Edit with your credentials:
   ```bash
   $EDITOR ~/.secrets
   ```

3. The file includes sections for:
   - AWS credentials and configuration
   - API keys (GitHub, OpenAI, cloud providers)
   - Database credentials
   - Development environment variables
   - 1Password CLI integration examples

### Security Best Practices

- **Never commit** `.secrets` to version control
- **Use 600 permissions** (owner read/write only)
- **Rotate credentials** regularly
- **Use environment-specific** values (not production in development)
- **Consider 1Password CLI** for production secrets

### 1Password CLI Integration

For enhanced security, use 1Password CLI to retrieve secrets:

```bash
# In .secrets file
export GITHUB_TOKEN="$(op read 'op://Private/GitHub Token/credential')"
export AWS_ACCESS_KEY_ID="$(op read 'op://Private/AWS Dev/username')"
```

## 🛠️ Configuration

### Environment Variables

Key environment variables (configured in `config/exports.zsh`):

```bash
# Development environment
EDITOR="code -w"              # VS Code as default editor
NODE_ENV="development"        # Development mode
LOCAL_RUN="true"             # Local development flag

# Multi-architecture Homebrew support
HOMEBREW_PREFIX              # /opt/homebrew (Apple Silicon) or /usr/local (Intel)

# Language-specific settings
NODE_OPTIONS="--max-old-space-size=4096"  # Node.js memory limit
PYTHONDONTWRITEBYTECODE=1                  # Don't create .pyc files
```

### Aliases

Essential aliases for daily development:

```bash
# Git shortcuts
gs="git status"
ga="git add"
gc="git commit"
gp="git push"
gl="git pull"

# Docker management
d="docker"
dc="docker-compose"
dclean="docker system prune"

# Kubernetes
k="kubectl"
kgp="kubectl get pods"
kctx="kubectl config use-context"

# AWS
awsp="aws-switch"             # Interactive profile switcher
```

### Functions

Powerful utility functions:

```bash
# Development
mkd <dir>                     # Create and enter directory
backup <file>                 # Create timestamped backup
extract <archive>             # Universal archive extractor
env-info                      # Show environment information

# Git utilities
git-cleanup                   # Remove merged branches
gccm <type> <message>         # Conventional commits

# Security
check-secrets [dir]           # Scan for exposed secrets
genpass [length]              # Generate secure password

# Development tools
node-use <version>            # Switch Node.js version
python-use <version>          # Switch Python version
aws-switch                    # Interactive AWS profile switcher
```

## 🚀 Development Workflows

### Node.js Development

```bash
# Install and use Node.js version
node-install 18.17.0
node-use lts

# Project initialization
node-init my-app react
cd my-app

# Package management
npm-audit                     # Security audit
npm-clean                     # Clean cache and node_modules
```

### Python Development

```bash
# Install and use Python version
python-install 3.11.5
python-use 3.11.5

# Virtual environment management
mkvenv my-project
activate-venv
pip-audit                     # Security audit
```

### AWS Operations

```bash
# Switch profiles interactively
aws-switch

# Get current identity
aws-whoami

# List resources
aws-ec2-list us-west-2
aws-s3-list
```

### Docker Management

```bash
# System information
docker-info

# Comprehensive cleanup
docker-cleanup

# Security scanning
docker-security-scan my-image:latest
```

### Kubernetes Operations

```bash
# Context and namespace switching
kctx-switch
kns-switch

# Enhanced pod operations
kpods production
klogs my-pod app-container production
kexec my-pod /bin/bash production

# Troubleshooting
k8s-problems
k8s-health
```

## 🔧 Customization

### Adding Custom Configuration

1. **Local Overrides**: Create `~/.zshrc.local` for machine-specific settings
2. **Local Exports**: Create `~/.exports.local` for additional environment variables
3. **Custom Functions**: Add to `config/functions.zsh` or create new files in `config/`

### Modifying Existing Configuration

The modular architecture makes customization easy:

- **Aliases**: Edit `config/aliases.zsh`
- **Environment Variables**: Edit `config/exports.zsh`
- **Functions**: Edit `config/functions.zsh`
- **Tool-specific**: Edit respective files (e.g., `config/aws.zsh`)

### Platform-Specific Configuration

The configuration automatically detects and adapts to:

- **macOS**: Uses Homebrew paths, macOS-specific commands
- **Linux**: Uses appropriate package managers and paths
- **WSL**: Handles Windows Subsystem for Linux specifics
- **Cloud Environments**: Detects Codespaces, devcontainers

## 🐛 Troubleshooting

### Common Issues

1. **Permission Errors**:
   ```bash
   chmod 600 ~/.secrets
   ```

2. **Oh My Zsh Not Loading**:
   ```bash
   # Check if Oh My Zsh is installed
   ls ~/.oh-my-zsh

   # Reinstall if missing
   sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
   ```

3. **Symlinks Not Working**:
   ```bash
   # Check symlinks
   ls -la ~/.zshrc ~/config

   # Recreate if needed
   ln -sf "$PWD/.zshrc" ~/.zshrc
   ln -sf "$PWD/config" ~/config
   ```

4. **Tools Not Found**:
   ```bash
   # Check environment information
   env-info

   # Reload configuration
   source ~/.zshrc
   ```

### Diagnostic Commands

```bash
# Environment information
env-info

# Check for issues
python-doctor
node-doctor
aws-validate

# Check secrets file permissions
validate-secrets-permissions

# Scan for exposed secrets
check-secrets
```

### Getting Help

1. **Check Logs**: Installation logs are saved to `~/.dotfiles_install.log`
2. **Backup Recovery**: Failed installations create backups in `~/.dotfiles_backup_*`
3. **Reset Configuration**: Remove symlinks and restore from backup

## 🔄 Updates and Maintenance

### Updating Dotfiles

```bash
cd ~/dotfiles
git pull origin main
source ~/.zshrc
```

### Updating Tools

```bash
# Update all system packages
system-update

# Update specific tools
brew upgrade                  # macOS
npm update -g                # Node.js packages
pip install --upgrade pip    # Python packages
```

### Regular Maintenance

```bash
# Clean caches
clean-cache

# Update and clean Docker
docker-cleanup-all

# Check for security issues
npm-audit
pip-audit
check-secrets
```

## 🔒 Security Considerations

### Best Practices

1. **Regular Updates**: Keep tools and dependencies updated
2. **Secret Rotation**: Regularly rotate API keys and credentials
3. **Permission Audits**: Regularly check file permissions
4. **Security Scanning**: Use built-in security functions

### What's Protected

- **Secrets File**: 600 permissions, excluded from Git
- **API Keys**: Template-based with validation
- **Commands**: Safety confirmations for destructive operations
- **Environment**: Separate configs for different environments

### What to Watch

- **Exposed Credentials**: Use `check-secrets` regularly
- **File Permissions**: Monitor `.secrets` file permissions
- **Dependencies**: Keep packages updated for security patches

## 📄 License

MIT License - feel free to use and modify as needed.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test your changes thoroughly
4. Submit a pull request

## 📚 Additional Resources

- [Oh My Zsh Documentation](https://ohmyz.sh/)
- [Zsh Manual](http://zsh.sourceforge.net/Doc/)
- [Security Best Practices for Dotfiles](https://github.com/thoughtbot/dotfiles)
- [1Password CLI Documentation](https://developer.1password.com/docs/cli/)

---

**Remember**: Security is a journey, not a destination. Regularly review and update your configuration to maintain security best practices.