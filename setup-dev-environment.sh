#!/bin/bash

# Setup script for development environment with NVM, Python (uv), Rust, and other tools
# This script installs and configures development tools and languages

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect package manager
detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        PKG_MANAGER="apt"
        INSTALL_CMD="sudo apt-get install -y"
        UPDATE_CMD="sudo apt-get update"
    elif command -v yum &> /dev/null; then
        PKG_MANAGER="yum"
        INSTALL_CMD="sudo yum install -y"
        UPDATE_CMD="sudo yum update"
    elif command -v dnf &> /dev/null; then
        PKG_MANAGER="dnf"
        INSTALL_CMD="sudo dnf install -y"
        UPDATE_CMD="sudo dnf update"
    elif command -v pacman &> /dev/null; then
        PKG_MANAGER="pacman"
        INSTALL_CMD="sudo pacman -S --noconfirm"
        UPDATE_CMD="sudo pacman -Sy"
    elif command -v brew &> /dev/null; then
        PKG_MANAGER="brew"
        INSTALL_CMD="brew install"
        UPDATE_CMD="brew update"
    else
        log_error "No supported package manager found!"
        exit 1
    fi
    log_info "Detected package manager: $PKG_MANAGER"
}

# Update system packages
update_system() {
    log_info "Updating system packages..."
    $UPDATE_CMD
    log_success "System packages updated"
}

# Install basic development dependencies
install_dependencies() {
    log_info "Installing basic development dependencies..."
    
    case $PKG_MANAGER in
        "apt")
            $INSTALL_CMD curl wget git build-essential software-properties-common \
                python3 python3-pip python3-dev \
                pkg-config libssl-dev
            ;;
        "yum"|"dnf")
            $INSTALL_CMD curl wget git gcc gcc-c++ make \
                python3 python3-pip python3-devel \
                openssl-devel
            ;;
        "pacman")
            $INSTALL_CMD curl wget git base-devel \
                python python-pip \
                openssl
            ;;
        "brew")
            $INSTALL_CMD curl wget git \
                python3 \
                openssl
            ;;
    esac
    
    log_success "Basic development dependencies installed"
}

# Install Node Version Manager (NVM)
install_nvm() {
    log_info "Installing Node Version Manager (NVM)..."
    
    if [ -d "$HOME/.nvm" ]; then
        log_warning "NVM is already installed"
    else
        # Install NVM
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
        
        # Add NVM to shell configuration
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
        
        # Install latest LTS version of Node.js
        nvm install --lts
        nvm use --lts
        
        log_success "NVM and Node.js LTS installed"
    fi
}

# Install Python uv (fast pip alternative)
install_python_uv() {
    log_info "Installing Python uv (fast pip alternative)..."
    
    if command -v uv &> /dev/null; then
        log_warning "uv is already installed"
    else
        # Install pipx if not already installed
        if ! command -v pipx &> /dev/null; then
            python3 -m pip install --user pipx
            python3 -m pipx ensurepath
        fi
        
        # Install uv using pipx
        pipx install uv
        
        log_success "Python uv installed"
    fi
    
    # Install essential Python packages
    log_info "Installing essential Python packages..."
    uv pip install numpy pandas matplotlib jupyter ipython black flake8 mypy
    log_success "Essential Python packages installed"
}

# Install Rust and cargo
install_rust() {
    log_info "Installing Rust and cargo..."
    
    if command -v rustc &> /dev/null && command -v cargo &> /dev/null; then
        log_warning "Rust is already installed"
        
        # Update Rust
        rustup update
    else
        # Install Rust
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        
        # Add Rust to the PATH
        export PATH="$HOME/.cargo/bin:$PATH"
        
        log_success "Rust and cargo installed"
    fi
    
    # Install essential Rust packages
    log_info "Installing essential Rust packages..."
    cargo install cargo-edit cargo-watch cargo-expand cargo-update cargo-outdated
    log_success "Essential Rust packages installed"
}

# Install Docker
install_docker() {
    log_info "Installing Docker..."
    
    if command -v docker &> /dev/null; then
        log_warning "Docker is already installed"
    else
        case $PKG_MANAGER in
            "apt")
                # Setup Docker repository
                $INSTALL_CMD apt-transport-https ca-certificates gnupg lsb-release
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                
                # Install Docker
                sudo apt-get update
                $INSTALL_CMD docker-ce docker-ce-cli containerd.io
                ;;
            "yum")
                # Setup Docker repository
                $INSTALL_CMD yum-utils
                sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
                
                # Install Docker
                $INSTALL_CMD docker-ce docker-ce-cli containerd.io
                ;;
            "dnf")
                # Setup Docker repository
                $INSTALL_CMD dnf-plugins-core
                sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
                
                # Install Docker
                $INSTALL_CMD docker-ce docker-ce-cli containerd.io
                ;;
            "pacman")
                $INSTALL_CMD docker
                ;;
            "brew")
                $INSTALL_CMD docker docker-compose
                ;;
        esac
        
        # Start Docker service
        if [ "$PKG_MANAGER" != "brew" ]; then
            sudo systemctl enable docker
            sudo systemctl start docker
        fi
        
        # Add current user to docker group
        if [ "$PKG_MANAGER" != "brew" ]; then
            sudo usermod -aG docker $USER
            log_warning "You need to log out and log back in for docker group changes to take effect"
        fi
        
        log_success "Docker installed"
    fi
}

# Install Go
install_go() {
    log_info "Installing Go..."
    
    if command -v go &> /dev/null; then
        log_warning "Go is already installed"
    else
        case $PKG_MANAGER in
            "apt")
                $INSTALL_CMD golang-go
                ;;
            "yum"|"dnf")
                $INSTALL_CMD golang
                ;;
            "pacman")
                $INSTALL_CMD go
                ;;
            "brew")
                $INSTALL_CMD go
                ;;
        esac
        
        # Setup Go workspace
        mkdir -p $HOME/go/{bin,pkg,src}
        
        # Add Go to PATH
        echo 'export GOPATH=$HOME/go' >> $HOME/.zshrc
        echo 'export PATH=$PATH:$GOPATH/bin' >> $HOME/.zshrc
        
        log_success "Go installed"
    fi
}

# Install development tools and utilities
install_dev_tools() {
    log_info "Installing development tools and utilities..."
    
    case $PKG_MANAGER in
        "apt")
            $INSTALL_CMD jq httpie htop neofetch silversearcher-ag bat exa
            ;;
        "yum"|"dnf")
            $INSTALL_CMD jq httpie htop neofetch the_silver_searcher bat
            # Install exa from GitHub for RHEL/CentOS/Fedora
            ;;
        "pacman")
            $INSTALL_CMD jq httpie htop neofetch the_silver_searcher bat exa
            ;;
        "brew")
            $INSTALL_CMD jq httpie htop neofetch ag bat exa
            ;;
    esac
    
    # If bat is installed as batcat (Ubuntu/Debian), create an alias
    if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
        echo 'alias bat="batcat"' >> $HOME/.zshrc
    fi
    
    # If exa is not available through package manager, install it manually
    if ! command -v exa &> /dev/null; then
        log_info "Installing exa manually..."
        cargo install exa
        log_success "exa installed via cargo"
    fi
    
    log_success "Development tools and utilities installed"
}

# Add aliases and configurations to zshrc
setup_dev_config() {
    log_info "Setting up development configurations..."
    
    # Add aliases to .zshrc
    cat >> "$HOME/.zshrc" << 'EOF'

# Development aliases
alias ll="exa -la --git --icons"
alias ls="exa --icons"
alias lt="exa -T --icons"
alias cat="bat --style=plain"
alias g="git"
alias gs="git status"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias py="python3"
alias ipy="ipython"
alias pip="uv pip"

# Node.js and NVM configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Rust configuration
export PATH="$HOME/.cargo/bin:$PATH"

# Go configuration
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"

# Python configuration
export PATH="$HOME/.local/bin:$PATH"

# Custom functions
function mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Customize terminal title
precmd() {
  print -Pn "\e]0;%n@%m: %~\a"
}
EOF
    
    log_success "Development configurations added to .zshrc"
}

# Main installation function
main() {
    log_info "Starting development environment setup..."
    
    detect_package_manager
    update_system
    install_dependencies
    
    # Install development tools
    install_nvm
    install_python_uv
    install_rust
    install_docker
    install_go
    install_dev_tools
    
    # Setup configurations
    setup_dev_config
    
    log_success "Development environment setup completed!"
    log_info "Please restart your terminal or run 'source ~/.zshrc' to apply changes"
}

# Handle script interruption
trap 'log_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"