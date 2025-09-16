#!/usr/bin/env zsh

# ==========================================
# SECURE DOTFILES - NODE.JS CONFIGURATION
# ==========================================
# Node.js and FNM (Fast Node Manager) setup
# Security-focused with automatic version switching

# ==========================================
# FNM INITIALIZATION
# ==========================================

# Initialize FNM (Fast Node Manager) if available
if command -v fnm &>/dev/null; then
    # Initialize FNM
    eval "$(fnm env --use-on-cd)"

    # Add completion
    eval "$(fnm completions --shell zsh)"

    echo "✅ FNM initialized with auto-switching enabled"
elif [[ -f "$HOME/.fnm/fnm" ]]; then
    # FNM installed in home directory
    export PATH="$HOME/.fnm:$PATH"
    eval "$(fnm env --use-on-cd)"
    eval "$(fnm completions --shell zsh)"

    echo "✅ FNM initialized from ~/.fnm"
elif [[ -f "/usr/local/bin/fnm" ]]; then
    # FNM installed via Homebrew or system package manager
    eval "$(fnm env --use-on-cd)"
    eval "$(fnm completions --shell zsh)"

    echo "✅ FNM initialized from system installation"
fi

# ==========================================
# NODE VERSION MANAGEMENT
# ==========================================

# Switch Node.js version with FNM
node-use() {
    local version="$1"

    if [[ -z "$version" ]]; then
        echo "Usage: node-use <version>"
        echo "Example: node-use 18.17.0"
        echo "Example: node-use lts"
        echo "Example: node-use latest"
        echo ""
        echo "Available versions:"
        fnm list 2>/dev/null || echo "❌ FNM not available"
        return 1
    fi

    if ! command -v fnm &>/dev/null; then
        echo "❌ FNM not installed"
        echo "Install with: curl -fsSL https://fnm.vercel.app/install | bash"
        return 1
    fi

    # Check if version is installed
    if ! fnm list | grep -q "$version"; then
        echo "📦 Version $version not installed. Installing..."
        fnm install "$version"
    fi

    # Use the version
    fnm use "$version"

    if [[ $? -eq 0 ]]; then
        echo "✅ Switched to Node.js $version"
        node-info
    else
        echo "❌ Failed to switch to Node.js $version"
        return 1
    fi
}

# Install and use Node.js version
node-install() {
    local version="${1:-lts}"

    if ! command -v fnm &>/dev/null; then
        echo "❌ FNM not installed"
        return 1
    fi

    echo "📦 Installing Node.js $version..."
    fnm install "$version"

    if [[ $? -eq 0 ]]; then
        echo "✅ Node.js $version installed successfully"

        read "use_now?Use this version now? (y/N): "
        if [[ "$use_now" =~ ^[Yy]$ ]]; then
            fnm use "$version"
            node-info
        fi
    else
        echo "❌ Failed to install Node.js $version"
        return 1
    fi
}

# List installed Node.js versions
node-list() {
    echo "📋 Installed Node.js Versions:"
    echo "============================="

    if command -v fnm &>/dev/null; then
        fnm list
    else
        echo "❌ FNM not available"
        return 1
    fi
}

# List available Node.js versions for installation
node-list-remote() {
    echo "🌐 Available Node.js Versions:"
    echo "============================="

    if command -v fnm &>/dev/null; then
        fnm list-remote | head -20
        echo ""
        echo "... (showing first 20 versions)"
        echo "Use 'fnm list-remote' to see all versions"
    else
        echo "❌ FNM not available"
        return 1
    fi
}

# Show current Node.js information
node-info() {
    echo "📊 Node.js Environment Information:"
    echo "==================================="

    if command -v node &>/dev/null; then
        echo "Node.js version: $(node --version)"
        echo "Node.js path: $(which node)"
    else
        echo "❌ Node.js not available"
    fi

    if command -v npm &>/dev/null; then
        echo "npm version: $(npm --version)"
        echo "npm path: $(which npm)"
    else
        echo "❌ npm not available"
    fi

    if command -v yarn &>/dev/null; then
        echo "Yarn version: $(yarn --version)"
        echo "Yarn path: $(which yarn)"
    fi

    if command -v pnpm &>/dev/null; then
        echo "pnpm version: $(pnpm --version)"
        echo "pnpm path: $(which pnpm)"
    fi

    if command -v fnm &>/dev/null; then
        echo "FNM version: $(fnm --version)"
        echo "Current FNM alias: $(fnm current 2>/dev/null || echo 'None')"
    fi

    echo ""
    echo "Node.js global directory: $(npm config get prefix 2>/dev/null || echo 'Unknown')"
    echo "Node modules path: $(npm root -g 2>/dev/null || echo 'Unknown')"
}

# ==========================================
# NPM UTILITIES
# ==========================================

# Update npm to latest version
npm-update() {
    echo "📦 Updating npm to latest version..."

    if ! command -v npm &>/dev/null; then
        echo "❌ npm not available"
        return 1
    fi

    npm install -g npm@latest

    if [[ $? -eq 0 ]]; then
        echo "✅ npm updated successfully"
        echo "New version: $(npm --version)"
    else
        echo "❌ Failed to update npm"
        return 1
    fi
}

# List globally installed npm packages
npm-global() {
    echo "🌍 Global npm Packages:"
    echo "======================"

    if command -v npm &>/dev/null; then
        npm list -g --depth=0
    else
        echo "❌ npm not available"
        return 1
    fi
}

# Clean npm cache and node_modules
npm-clean() {
    echo "🧹 Cleaning npm cache and node_modules..."

    # Clean npm cache
    if command -v npm &>/dev/null; then
        npm cache clean --force
        echo "✅ npm cache cleaned"
    fi

    # Remove node_modules if it exists
    if [[ -d "node_modules" ]]; then
        read "remove_modules?Remove node_modules directory? (y/N): "
        if [[ "$remove_modules" =~ ^[Yy]$ ]]; then
            rm -rf node_modules
            echo "✅ node_modules removed"
        fi
    else
        echo "ℹ️  No node_modules directory found"
    fi

    # Remove package-lock.json if it exists
    if [[ -f "package-lock.json" ]]; then
        read "remove_lock?Remove package-lock.json? (y/N): "
        if [[ "$remove_lock" =~ ^[Yy]$ ]]; then
            rm package-lock.json
            echo "✅ package-lock.json removed"
        fi
    fi

    echo "🧹 Cleanup completed"
}

# Check for outdated packages
npm-outdated() {
    echo "📊 Checking for outdated packages..."

    if ! command -v npm &>/dev/null; then
        echo "❌ npm not available"
        return 1
    fi

    if [[ ! -f "package.json" ]]; then
        echo "❌ No package.json found in current directory"
        return 1
    fi

    echo ""
    echo "📦 Local packages:"
    npm outdated

    echo ""
    read "check_global?Check global packages too? (y/N): "
    if [[ "$check_global" =~ ^[Yy]$ ]]; then
        echo ""
        echo "🌍 Global packages:"
        npm outdated -g
    fi
}

# Security audit for npm packages
npm-audit() {
    echo "🔍 Running npm security audit..."

    if ! command -v npm &>/dev/null; then
        echo "❌ npm not available"
        return 1
    fi

    if [[ ! -f "package.json" ]]; then
        echo "❌ No package.json found in current directory"
        return 1
    fi

    npm audit

    echo ""
    read "fix_issues?Attempt to fix issues automatically? (y/N): "
    if [[ "$fix_issues" =~ ^[Yy]$ ]]; then
        npm audit fix
        echo "✅ Attempted to fix security issues"
    fi
}

# ==========================================
# YARN UTILITIES
# ==========================================

# Yarn global packages
yarn-global() {
    echo "🌍 Global Yarn Packages:"
    echo "======================="

    if command -v yarn &>/dev/null; then
        yarn global list
    else
        echo "❌ Yarn not available"
        return 1
    fi
}

# Clean yarn cache
yarn-clean() {
    echo "🧹 Cleaning Yarn cache..."

    if command -v yarn &>/dev/null; then
        yarn cache clean
        echo "✅ Yarn cache cleaned"
    else
        echo "❌ Yarn not available"
        return 1
    fi
}

# ==========================================
# PROJECT UTILITIES
# ==========================================

# Initialize new Node.js project
node-init() {
    local project_name="$1"
    local template="${2:-basic}"

    if [[ -z "$project_name" ]]; then
        echo "Usage: node-init <project_name> [template]"
        echo "Templates: basic, express, react, vue, typescript"
        return 1
    fi

    echo "🚀 Creating new Node.js project: $project_name"
    echo "Template: $template"

    # Create project directory
    mkdir -p "$project_name"
    cd "$project_name"

    # Initialize package.json
    npm init -y

    case "$template" in
        "express")
            npm install express
            npm install -D nodemon
            echo "✅ Express.js project initialized"
            ;;
        "react")
            npx create-react-app . --template typescript
            echo "✅ React project initialized"
            ;;
        "vue")
            npx @vue/cli create . --default
            echo "✅ Vue.js project initialized"
            ;;
        "typescript")
            npm install -D typescript @types/node ts-node
            npx tsc --init
            echo "✅ TypeScript project initialized"
            ;;
        *)
            echo "✅ Basic Node.js project initialized"
            ;;
    esac

    # Create basic .gitignore
    cat > .gitignore << EOF
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
dist/
build/
coverage/
.nyc_output/
.cache/
.parcel-cache/
.DS_Store
EOF

    echo "📁 Project structure created:"
    ls -la
}

# Check project dependencies for security issues
node-security-check() {
    echo "🔍 Running comprehensive security check..."

    if [[ ! -f "package.json" ]]; then
        echo "❌ No package.json found in current directory"
        return 1
    fi

    # npm audit
    echo "📊 npm audit:"
    npm audit

    # Check for known vulnerabilities using snyk if available
    if command -v snyk &>/dev/null; then
        echo ""
        echo "📊 Snyk vulnerability check:"
        snyk test
    else
        echo ""
        echo "ℹ️  Install snyk for more comprehensive security scanning: npm install -g snyk"
    fi

    # Check for outdated packages
    echo ""
    echo "📊 Outdated packages:"
    npm outdated

    # Check package-lock.json
    if [[ -f "package-lock.json" ]]; then
        echo ""
        echo "✅ package-lock.json present (good for security)"
    else
        echo ""
        echo "⚠️  No package-lock.json found (consider running 'npm install' to create one)"
    fi
}

# ==========================================
# ENVIRONMENT SETUP
# ==========================================

# Set up Node.js development environment
node-setup-env() {
    echo "⚙️  Setting up Node.js development environment..."

    # Check if FNM is installed
    if ! command -v fnm &>/dev/null; then
        echo "📦 Installing FNM..."
        curl -fsSL https://fnm.vercel.app/install | bash
        source ~/.zshrc
    fi

    # Install latest LTS Node.js
    echo "📦 Installing latest LTS Node.js..."
    fnm install --lts
    fnm use lts-latest

    # Update npm
    echo "📦 Updating npm..."
    npm install -g npm@latest

    # Install useful global packages
    echo "📦 Installing useful global packages..."
    local global_packages=(
        "yarn"                    # Alternative package manager
        "pnpm"                    # Fast package manager
        "typescript"              # TypeScript compiler
        "ts-node"                # TypeScript execution
        "nodemon"                # Development server
        "prettier"               # Code formatter
        "eslint"                 # Code linter
        "http-server"            # Simple HTTP server
        "json-server"            # Mock REST API
        "npm-check-updates"      # Update package.json
        "lighthouse"             # Performance auditing
        "snyk"                   # Security scanning
    )

    for package in "${global_packages[@]}"; do
        if ! npm list -g "$package" &>/dev/null; then
            echo "Installing $package..."
            npm install -g "$package"
        else
            echo "✅ $package already installed"
        fi
    done

    echo ""
    echo "✅ Node.js development environment setup completed!"
    node-info
}

# ==========================================
# TROUBLESHOOTING
# ==========================================

# Fix common Node.js issues
node-doctor() {
    echo "🩺 Node.js Health Check:"
    echo "======================="

    # Check Node.js installation
    if command -v node &>/dev/null; then
        echo "✅ Node.js installed: $(node --version)"
    else
        echo "❌ Node.js not found"
        echo "Install with: fnm install lts"
    fi

    # Check npm installation
    if command -v npm &>/dev/null; then
        echo "✅ npm installed: $(npm --version)"
    else
        echo "❌ npm not found"
    fi

    # Check FNM installation
    if command -v fnm &>/dev/null; then
        echo "✅ FNM installed: $(fnm --version)"
    else
        echo "❌ FNM not found"
        echo "Install with: curl -fsSL https://fnm.vercel.app/install | bash"
    fi

    # Check npm configuration
    echo ""
    echo "📋 npm Configuration:"
    echo "Registry: $(npm config get registry)"
    echo "Prefix: $(npm config get prefix)"
    echo "Cache: $(npm config get cache)"

    # Check for common issues
    echo ""
    echo "🔍 Common Issues Check:"

    # Check npm permissions
    local npm_prefix=$(npm config get prefix)
    if [[ "$npm_prefix" == "/usr/local" ]]; then
        echo "⚠️  npm prefix is set to /usr/local (may cause permission issues)"
        echo "Fix with: npm config set prefix ~/.npm-global"
    else
        echo "✅ npm prefix looks good: $npm_prefix"
    fi

    # Check for node_modules in wrong places
    if [[ -d "/usr/local/lib/node_modules" ]]; then
        local module_count=$(ls /usr/local/lib/node_modules | wc -l)
        if [[ $module_count -gt 5 ]]; then
            echo "⚠️  Many global modules in /usr/local/lib/node_modules ($module_count modules)"
            echo "Consider using a Node version manager like FNM"
        fi
    fi

    # Check PATH
    echo ""
    echo "📍 NODE PATH Check:"
    echo "Node binary: $(which node 2>/dev/null || echo 'Not found')"
    echo "npm binary: $(which npm 2>/dev/null || echo 'Not found')"

    echo ""
    echo "🩺 Health check completed"
}

# ==========================================
# AUTO-COMPLETION SETUP
# ==========================================

# Enable npm completion
if command -v npm &>/dev/null; then
    source <(npm completion)
fi

# Enable yarn completion
if command -v yarn &>/dev/null && [[ -f "$(yarn global bin)/yarn" ]]; then
    # Yarn completion is typically handled by Oh My Zsh plugin
    true
fi