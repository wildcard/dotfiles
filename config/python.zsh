#!/usr/bin/env zsh

# ==========================================
# SECURE DOTFILES - PYTHON CONFIGURATION
# ==========================================
# Python and Pyenv setup with virtual environment management
# Security-focused with OpenSSL configuration for macOS

# ==========================================
# PYENV INITIALIZATION
# ==========================================

# Initialize Pyenv if available
if command -v pyenv &>/dev/null; then
    # Initialize pyenv
    eval "$(pyenv init -)"

    # Initialize pyenv virtualenv if available
    if pyenv commands | grep -q virtualenv-init; then
        eval "$(pyenv virtualenv-init -)"
    fi

    echo "✅ Pyenv initialized"
elif [[ -d "$HOME/.pyenv" ]]; then
    # Pyenv installed in home directory
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"

    if pyenv commands | grep -q virtualenv-init; then
        eval "$(pyenv virtualenv-init -)"
    fi

    echo "✅ Pyenv initialized from ~/.pyenv"
fi

# ==========================================
# MACOS OPENSSL CONFIGURATION
# ==========================================

# Configure OpenSSL for macOS (needed for Python compilation)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Homebrew OpenSSL configuration
    if [[ -d "$HOMEBREW_PREFIX/opt/openssl@3" ]]; then
        export LDFLAGS="-L$HOMEBREW_PREFIX/opt/openssl@3/lib"
        export CPPFLAGS="-I$HOMEBREW_PREFIX/opt/openssl@3/include"
        export PKG_CONFIG_PATH="$HOMEBREW_PREFIX/opt/openssl@3/lib/pkgconfig"
    elif [[ -d "$HOMEBREW_PREFIX/opt/openssl@1.1" ]]; then
        export LDFLAGS="-L$HOMEBREW_PREFIX/opt/openssl@1.1/lib"
        export CPPFLAGS="-I$HOMEBREW_PREFIX/opt/openssl@1.1/include"
        export PKG_CONFIG_PATH="$HOMEBREW_PREFIX/opt/openssl@1.1/lib/pkgconfig"
    fi

    # Additional build flags for macOS
    export PYTHON_BUILD_ARIA2_OPTS="-x 10 -k 1M"
    export PYTHON_CONFIGURE_OPTS="--enable-shared --enable-optimizations"
fi

# ==========================================
# PYTHON VERSION MANAGEMENT
# ==========================================

# Switch Python version with Pyenv
python-use() {
    local version="$1"

    if [[ -z "$version" ]]; then
        echo "Usage: python-use <version>"
        echo "Example: python-use 3.11.5"
        echo "Example: python-use 3.10"
        echo ""
        echo "Available versions:"
        pyenv versions 2>/dev/null || echo "❌ Pyenv not available"
        return 1
    fi

    if ! command -v pyenv &>/dev/null; then
        echo "❌ Pyenv not installed"
        echo "Install with: curl https://pyenv.run | bash"
        return 1
    fi

    # Check if version is installed
    if ! pyenv versions | grep -q "$version"; then
        echo "📦 Version $version not installed. Installing..."
        python-install "$version"
    fi

    # Set the version
    pyenv global "$version"

    if [[ $? -eq 0 ]]; then
        echo "✅ Switched to Python $version"
        python-info
    else
        echo "❌ Failed to switch to Python $version"
        return 1
    fi
}

# Install Python version with Pyenv
python-install() {
    local version="${1:-3.11.5}"

    if ! command -v pyenv &>/dev/null; then
        echo "❌ Pyenv not installed"
        return 1
    fi

    echo "📦 Installing Python $version..."

    # macOS-specific pre-installation checks
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "🔧 macOS detected - checking dependencies..."

        # Check for required build dependencies
        local missing_deps=()

        if ! brew list --formula | grep -q "^openssl@"; then
            missing_deps+=("openssl")
        fi

        if ! brew list --formula | grep -q "^readline$"; then
            missing_deps+=("readline")
        fi

        if ! brew list --formula | grep -q "^sqlite$"; then
            missing_deps+=("sqlite3")
        fi

        if ! brew list --formula | grep -q "^xz$"; then
            missing_deps+=("xz")
        fi

        if ! brew list --formula | grep -q "^zlib$"; then
            missing_deps+=("zlib")
        fi

        if [[ ${#missing_deps[@]} -gt 0 ]]; then
            echo "⚠️  Missing dependencies: ${missing_deps[*]}"
            read "install_deps?Install missing dependencies with Homebrew? (y/N): "
            if [[ "$install_deps" =~ ^[Yy]$ ]]; then
                brew install "${missing_deps[@]}"
            else
                echo "⚠️  Proceeding without installing dependencies (may fail)"
            fi
        fi
    fi

    # Install Python version
    pyenv install "$version"

    if [[ $? -eq 0 ]]; then
        echo "✅ Python $version installed successfully"

        read "use_now?Use this version now? (y/N): "
        if [[ "$use_now" =~ ^[Yy]$ ]]; then
            pyenv global "$version"
            python-info
        fi
    else
        echo "❌ Failed to install Python $version"
        return 1
    fi
}

# List installed Python versions
python-list() {
    echo "📋 Installed Python Versions:"
    echo "============================="

    if command -v pyenv &>/dev/null; then
        pyenv versions
    else
        echo "❌ Pyenv not available"
        return 1
    fi
}

# List available Python versions for installation
python-list-remote() {
    echo "🌐 Available Python Versions:"
    echo "============================="

    if command -v pyenv &>/dev/null; then
        pyenv install --list | grep -E "^\s*[0-9]+\.[0-9]+\.[0-9]+$" | tail -20
        echo ""
        echo "... (showing last 20 stable versions)"
        echo "Use 'pyenv install --list' to see all versions"
    else
        echo "❌ Pyenv not available"
        return 1
    fi
}

# Show current Python information
python-info() {
    echo "📊 Python Environment Information:"
    echo "=================================="

    if command -v python &>/dev/null; then
        echo "Python version: $(python --version)"
        echo "Python path: $(which python)"
    elif command -v python3 &>/dev/null; then
        echo "Python3 version: $(python3 --version)"
        echo "Python3 path: $(which python3)"
    else
        echo "❌ Python not available"
    fi

    if command -v pip &>/dev/null; then
        echo "pip version: $(pip --version | cut -d' ' -f2)"
        echo "pip path: $(which pip)"
    elif command -v pip3 &>/dev/null; then
        echo "pip3 version: $(pip3 --version | cut -d' ' -f2)"
        echo "pip3 path: $(which pip3)"
    else
        echo "❌ pip not available"
    fi

    if command -v pyenv &>/dev/null; then
        echo "Pyenv version: $(pyenv --version)"
        echo "Current Pyenv version: $(pyenv version)"
    fi

    # Virtual environment info
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "Virtual environment: $VIRTUAL_ENV"
        echo "Virtual env Python: $(python --version 2>/dev/null || echo 'Unknown')"
    else
        echo "Virtual environment: None active"
    fi

    echo ""
    echo "Python executable: $(python -c 'import sys; print(sys.executable)' 2>/dev/null || echo 'Unknown')"
    echo "Python site-packages: $(python -c 'import site; print(site.getsitepackages()[0])' 2>/dev/null || echo 'Unknown')"
}

# ==========================================
# VIRTUAL ENVIRONMENT MANAGEMENT
# ==========================================

# Create Python virtual environment
mkvenv() {
    local venv_name="${1:-venv}"
    local python_version="${2:-python3}"

    echo "🐍 Creating virtual environment: $venv_name"

    if command -v "$python_version" &>/dev/null; then
        "$python_version" -m venv "$venv_name"
        echo "✅ Virtual environment created: $venv_name"
        echo ""
        echo "To activate: source $venv_name/bin/activate"
        echo "To deactivate: deactivate"
    else
        echo "❌ Python version '$python_version' not found"
        return 1
    fi
}

# Smart virtual environment activator
activate-venv() {
    local venv_dirs=("venv" ".venv" "env" ".env" "virtualenv")
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

# Create virtual environment with common packages
mkvenv-full() {
    local venv_name="${1:-venv}"
    local python_version="${2:-python3}"

    echo "🐍 Creating full virtual environment: $venv_name"

    # Create virtual environment
    mkvenv "$venv_name" "$python_version"

    if [[ $? -ne 0 ]]; then
        return 1
    fi

    # Activate it
    source "$venv_name/bin/activate"

    # Upgrade pip
    echo "📦 Upgrading pip..."
    pip install --upgrade pip

    # Install common packages
    echo "📦 Installing common packages..."
    local common_packages=(
        "wheel"           # Package building
        "setuptools"      # Package management
        "requests"        # HTTP library
        "python-dotenv"   # Environment variables
        "black"           # Code formatter
        "flake8"          # Linter
        "pytest"          # Testing framework
        "ipython"         # Enhanced REPL
        "jupyter"         # Notebook environment
    )

    for package in "${common_packages[@]}"; do
        echo "Installing $package..."
        pip install "$package"
    done

    echo "✅ Full virtual environment setup completed!"
    python-info
}

# Remove virtual environment
rmvenv() {
    local venv_name="${1:-venv}"

    if [[ ! -d "$venv_name" ]]; then
        echo "❌ Virtual environment '$venv_name' not found"
        return 1
    fi

    echo "🗑️  Removing virtual environment: $venv_name"

    read "confirm?Are you sure? (y/N): "
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        # Deactivate if currently active
        if [[ "$VIRTUAL_ENV" == *"$venv_name"* ]]; then
            deactivate
        fi

        rm -rf "$venv_name"
        echo "✅ Virtual environment '$venv_name' removed"
    else
        echo "❌ Removal cancelled"
    fi
}

# ==========================================
# PACKAGE MANAGEMENT
# ==========================================

# Upgrade pip and common packages
pip-upgrade() {
    echo "📦 Upgrading pip and common packages..."

    # Upgrade pip
    pip install --upgrade pip

    # Common packages to upgrade
    local packages=(
        "wheel"
        "setuptools"
        "requests"
        "black"
        "flake8"
        "pytest"
    )

    for package in "${packages[@]}"; do
        if pip show "$package" &>/dev/null; then
            echo "Upgrading $package..."
            pip install --upgrade "$package"
        fi
    done

    echo "✅ Upgrade completed"
}

# Install packages from requirements.txt
pip-install-req() {
    local req_file="${1:-requirements.txt}"

    if [[ ! -f "$req_file" ]]; then
        echo "❌ Requirements file not found: $req_file"
        return 1
    fi

    echo "📦 Installing packages from $req_file..."
    pip install -r "$req_file"

    if [[ $? -eq 0 ]]; then
        echo "✅ Packages installed successfully"
    else
        echo "❌ Failed to install some packages"
        return 1
    fi
}

# Generate requirements.txt
pip-freeze() {
    local output_file="${1:-requirements.txt}"

    echo "📝 Generating requirements file: $output_file"
    pip freeze > "$output_file"

    if [[ $? -eq 0 ]]; then
        echo "✅ Requirements saved to $output_file"
        echo "Packages: $(wc -l < "$output_file")"
    else
        echo "❌ Failed to generate requirements"
        return 1
    fi
}

# Check for outdated packages
pip-outdated() {
    echo "📊 Checking for outdated packages..."

    if command -v pip &>/dev/null; then
        pip list --outdated
    else
        echo "❌ pip not available"
        return 1
    fi
}

# Security audit for Python packages
pip-audit() {
    echo "🔍 Running pip security audit..."

    # Check if pip-audit is installed
    if ! pip show pip-audit &>/dev/null; then
        echo "📦 pip-audit not installed. Installing..."
        pip install pip-audit
    fi

    pip-audit

    echo ""
    read "fix_issues?Attempt to fix issues automatically? (y/N): "
    if [[ "$fix_issues" =~ ^[Yy]$ ]]; then
        pip-audit --fix
        echo "✅ Attempted to fix security issues"
    fi
}

# ==========================================
# PROJECT UTILITIES
# ==========================================

# Initialize new Python project
python-init() {
    local project_name="$1"
    local template="${2:-basic}"

    if [[ -z "$project_name" ]]; then
        echo "Usage: python-init <project_name> [template]"
        echo "Templates: basic, flask, django, fastapi, data-science"
        return 1
    fi

    echo "🚀 Creating new Python project: $project_name"
    echo "Template: $template"

    # Create project directory
    mkdir -p "$project_name"
    cd "$project_name"

    # Create virtual environment
    mkvenv "venv"
    source venv/bin/activate

    # Create basic structure
    mkdir -p src tests docs

    case "$template" in
        "flask")
            pip install flask python-dotenv
            cat > src/app.py << 'EOF'
from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello, World!'

if __name__ == '__main__':
    app.run(debug=True)
EOF
            echo "✅ Flask project initialized"
            ;;
        "django")
            pip install django
            django-admin startproject myproject .
            echo "✅ Django project initialized"
            ;;
        "fastapi")
            pip install fastapi uvicorn python-multipart
            cat > src/main.py << 'EOF'
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Hello World"}
EOF
            echo "✅ FastAPI project initialized"
            ;;
        "data-science")
            pip install numpy pandas matplotlib seaborn jupyter scikit-learn
            echo "✅ Data science project initialized"
            ;;
        *)
            pip install black flake8 pytest
            cat > src/__init__.py << 'EOF'
"""
Project package
"""
__version__ = "0.1.0"
EOF
            echo "✅ Basic Python project initialized"
            ;;
    esac

    # Create common files
    cat > requirements.txt << EOF
# Add your project dependencies here
EOF

    cat > .gitignore << EOF
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST
.env
.venv
env/
venv/
ENV/
env.bak/
venv.bak/
.pytest_cache/
.coverage
htmlcov/
.tox/
.cache
nosetests.xml
coverage.xml
*.cover
.hypothesis/
.DS_Store
EOF

    cat > README.md << EOF
# $project_name

## Setup

1. Create virtual environment:
   \`\`\`bash
   python -m venv venv
   source venv/bin/activate  # On Windows: venv\\Scripts\\activate
   \`\`\`

2. Install dependencies:
   \`\`\`bash
   pip install -r requirements.txt
   \`\`\`

## Development

Run tests:
\`\`\`bash
pytest
\`\`\`

Format code:
\`\`\`bash
black src/
\`\`\`

Lint code:
\`\`\`bash
flake8 src/
\`\`\`
EOF

    echo "📁 Project structure created:"
    ls -la
}

# ==========================================
# DEVELOPMENT TOOLS
# ==========================================

# Format Python code with Black
python-format() {
    local target="${1:-.}"

    if ! command -v black &>/dev/null; then
        echo "❌ Black not installed"
        echo "Install with: pip install black"
        return 1
    fi

    echo "🎨 Formatting Python code in: $target"
    black "$target"

    if [[ $? -eq 0 ]]; then
        echo "✅ Code formatted successfully"
    else
        echo "❌ Formatting failed"
        return 1
    fi
}

# Lint Python code with flake8
python-lint() {
    local target="${1:-.}"

    if ! command -v flake8 &>/dev/null; then
        echo "❌ flake8 not installed"
        echo "Install with: pip install flake8"
        return 1
    fi

    echo "🔍 Linting Python code in: $target"
    flake8 "$target"

    if [[ $? -eq 0 ]]; then
        echo "✅ No linting issues found"
    else
        echo "⚠️  Linting issues found"
        return 1
    fi
}

# Run Python tests with pytest
python-test() {
    local target="${1:-tests/}"

    if ! command -v pytest &>/dev/null; then
        echo "❌ pytest not installed"
        echo "Install with: pip install pytest"
        return 1
    fi

    if [[ ! -d "$target" && ! -f "$target" ]]; then
        echo "❌ Test target not found: $target"
        return 1
    fi

    echo "🧪 Running Python tests: $target"
    pytest "$target" -v

    if [[ $? -eq 0 ]]; then
        echo "✅ All tests passed"
    else
        echo "❌ Some tests failed"
        return 1
    fi
}

# ==========================================
# TROUBLESHOOTING
# ==========================================

# Python environment doctor
python-doctor() {
    echo "🩺 Python Environment Health Check:"
    echo "==================================="

    # Check Python installation
    if command -v python &>/dev/null; then
        echo "✅ Python installed: $(python --version)"
    elif command -v python3 &>/dev/null; then
        echo "✅ Python3 installed: $(python3 --version)"
    else
        echo "❌ Python not found"
        echo "Install with: pyenv install 3.11.5"
    fi

    # Check pip installation
    if command -v pip &>/dev/null; then
        echo "✅ pip installed: $(pip --version | cut -d' ' -f2)"
    else
        echo "❌ pip not found"
    fi

    # Check pyenv installation
    if command -v pyenv &>/dev/null; then
        echo "✅ Pyenv installed: $(pyenv --version)"
    else
        echo "❌ Pyenv not found"
        echo "Install with: curl https://pyenv.run | bash"
    fi

    # Check virtual environment
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "✅ Virtual environment active: $VIRTUAL_ENV"
    else
        echo "ℹ️  No virtual environment active"
    fi

    # Check common issues
    echo ""
    echo "🔍 Common Issues Check:"

    # Check SSL/TLS certificates (macOS)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if python -c "import ssl; print(ssl.get_default_verify_paths())" &>/dev/null; then
            echo "✅ SSL certificates accessible"
        else
            echo "⚠️  SSL certificate issues detected"
            echo "Run: /Applications/Python\\ 3.x/Install\\ Certificates.command"
        fi
    fi

    # Check pip configuration
    echo ""
    echo "📋 pip Configuration:"
    echo "User site: $(python -m site --user-site 2>/dev/null || echo 'Unknown')"
    echo "Cache dir: $(pip cache dir 2>/dev/null || echo 'Unknown')"

    echo ""
    echo "🩺 Health check completed"
}

# ==========================================
# ALIASES FOR CONVENIENCE
# ==========================================

# Python 3 aliases for consistency
alias python='python3'
alias pip='pip3'

# Virtual environment shortcuts
alias venv-activate='activate-venv'
alias venv-create='mkvenv'
alias venv-remove='rmvenv'