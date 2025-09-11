#!/bin/bash

# SSH Machine Setup Script
# Sets up basic development environment for SSH-accessible machines
# Includes zsh, vim, tmux, ranger, and other CLI tools

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

# Detect OS and package manager
detect_os_and_package_manager() {
    log_info "Detecting operating system and package manager..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$NAME
        OS_ID=$ID
        
        case $ID in
            debian|ubuntu|pop|linuxmint|elementary)
                PKG_MANAGER="apt"
                INSTALL_CMD="sudo apt-get install -y"
                UPDATE_CMD="sudo apt-get update"
                log_success "Detected $OS_NAME with apt package manager"
                ;;
            arch|manjaro|endeavouros)
                PKG_MANAGER="pacman"
                INSTALL_CMD="sudo pacman -S --noconfirm"
                UPDATE_CMD="sudo pacman -Sy"
                log_success "Detected $OS_NAME with pacman package manager"
                ;;
            fedora)
                PKG_MANAGER="dnf"
                INSTALL_CMD="sudo dnf install -y"
                UPDATE_CMD="sudo dnf update"
                log_success "Detected $OS_NAME with dnf package manager"
                ;;
            centos|rhel)
                PKG_MANAGER="yum"
                INSTALL_CMD="sudo yum install -y"
                UPDATE_CMD="sudo yum update"
                log_success "Detected $OS_NAME with yum package manager"
                ;;
            *)
                if command -v apt-get &> /dev/null; then
                    PKG_MANAGER="apt"
                    INSTALL_CMD="sudo apt-get install -y"
                    UPDATE_CMD="sudo apt-get update"
                elif command -v pacman &> /dev/null; then
                    PKG_MANAGER="pacman"
                    INSTALL_CMD="sudo pacman -S --noconfirm"
                    UPDATE_CMD="sudo pacman -Sy"
                elif command -v dnf &> /dev/null; then
                    PKG_MANAGER="dnf"
                    INSTALL_CMD="sudo dnf install -y"
                    UPDATE_CMD="sudo dnf update"
                elif command -v yum &> /dev/null; then
                    PKG_MANAGER="yum"
                    INSTALL_CMD="sudo yum install -y"
                    UPDATE_CMD="sudo yum update"
                else
                    log_error "Unsupported operating system: $OS_NAME"
                    exit 1
                fi
                ;;
        esac
    else
        # Fallback detection method
        if command -v apt-get &> /dev/null; then
            PKG_MANAGER="apt"
            INSTALL_CMD="sudo apt-get install -y"
            UPDATE_CMD="sudo apt-get update"
        elif command -v pacman &> /dev/null; then
            PKG_MANAGER="pacman"
            INSTALL_CMD="sudo pacman -S --noconfirm"
            UPDATE_CMD="sudo pacman -Sy"
        elif command -v dnf &> /dev/null; then
            PKG_MANAGER="dnf"
            INSTALL_CMD="sudo dnf install -y"
            UPDATE_CMD="sudo dnf update"
        elif command -v yum &> /dev/null; then
            PKG_MANAGER="yum"
            INSTALL_CMD="sudo yum install -y"
            UPDATE_CMD="sudo yum update"
        else
            log_error "Could not detect package manager"
            exit 1
        fi
    fi
}

# Update system
update_system() {
    log_info "Updating system packages..."
    $UPDATE_CMD
    log_success "System packages updated"
}

# Load package definitions
load_package_definitions() {
    log_info "Loading package definitions..."
    
    # Source the package definition files
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    if [ -f "$SCRIPT_DIR/scripts/packages-base.sh" ]; then
        source "$SCRIPT_DIR/scripts/packages-base.sh"
        log_success "Loaded base packages"
    else
        log_error "Base packages file not found"
        exit 1
    fi
}

# Install basic dependencies
install_dependencies() {
    log_info "Installing basic dependencies..."
    
    case $PKG_MANAGER in
        "apt")
            $INSTALL_CMD curl wget git build-essential software-properties-common
            ;;
        "yum"|"dnf")
            $INSTALL_CMD curl wget git gcc gcc-c++ make
            ;;
        "pacman")
            $INSTALL_CMD curl wget git base-devel
            ;;
    esac
    
    log_success "Basic dependencies installed"
}

# Install oh-my-zsh
install_oh_my_zsh() {
    log_info "Installing oh-my-zsh..."
    
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_warning "oh-my-zsh is already installed"
    else
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        log_success "oh-my-zsh installed"
    fi
}

# Install zsh plugins
install_zsh_plugins() {
    log_info "Installing zsh plugins..."
    
    # Install zsh-autosuggestions
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
        log_success "zsh-autosuggestions installed"
    else
        log_warning "zsh-autosuggestions already installed"
    fi
    
    # Install zsh-syntax-highlighting
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
        log_success "zsh-syntax-highlighting installed"
    else
        log_warning "zsh-syntax-highlighting already installed"
    fi
}

# Install vim-plug
install_vim_plug() {
    log_info "Installing vim-plug..."
    
    if [ -f "$HOME/.vim/autoload/plug.vim" ]; then
        log_warning "vim-plug is already installed"
    else
        curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        log_success "vim-plug installed"
    fi
}

# Install tmux plugin manager (tpm)
install_tpm() {
    log_info "Installing tmux plugin manager (tpm)..."
    
    if [ -d "$HOME/.tmux/plugins/tpm" ]; then
        log_warning "tpm is already installed"
    else
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
        log_success "tpm installed"
    fi
}

# Setup dotfiles using stow
setup_dotfiles() {
    log_info "Setting up dotfiles using stow..."
    
    # Get the script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Install stow if not already present
    case $PKG_MANAGER in
        apt)
            sudo apt-get install -y stow
            ;;
        pacman)
            sudo pacman -S --needed --noconfirm stow
            ;;
        dnf)
            sudo dnf install -y stow
            ;;
        yum)
            sudo yum install -y stow
            ;;
    esac
    
    # Stow each relevant configuration directory for SSH setup
    for dir in zsh vim tmux ranger; do
        if [ -d "$SCRIPT_DIR/$dir" ]; then
            log_info "Stowing $dir..."
            stow -v -R -t "$HOME" "$dir"
        else
            log_warning "Directory $dir not found, skipping"
        fi
    done
    
    log_success "Dotfiles set up"
}

# Create tmux sessionizer script
create_tmux_sessionizer() {
    log_info "Creating tmux sessionizer script..."
    
    mkdir -p "$HOME/bin"
    
    cat > "$HOME/bin/tmux-sessionizer" << 'EOF'
#!/usr/bin/env bash

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(find ~/projects ~/ -mindepth 1 -maxdepth 1 -type d | fzf)
fi

if [[ -z $selected ]]; then
    exit 0
fi

selected_name=$(basename "$selected" | tr . _)
tmux_running=$(pgrep tmux)

if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
    tmux new-session -s $selected_name -c $selected
    exit 0
fi

if ! tmux has-session -t=$selected_name 2> /dev/null; then
    tmux new-session -ds $selected_name -c $selected
fi

if [[ -z $TMUX ]]; then
    tmux attach-session -t $selected_name
else
    tmux switch-client -t $selected_name
fi
EOF

    chmod +x "$HOME/bin/tmux-sessionizer"
    
    # Add to PATH if not already in path
    if ! grep -q "export PATH=\"\$HOME/bin:\$PATH\"" "$HOME/.zshrc"; then
        echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.zshrc"
    fi
    
    log_success "tmux sessionizer created"
}

# Change default shell to zsh
change_shell_to_zsh() {
    log_info "Changing default shell to zsh..."
    
    if [[ "$SHELL" == *"zsh"* ]]; then
        log_warning "Shell is already zsh"
    else
        if command -v zsh &> /dev/null; then
            ZSH_PATH=$(which zsh)
            if grep -q "$ZSH_PATH" /etc/shells; then
                chsh -s "$ZSH_PATH"
                log_success "Default shell changed to zsh"
            else
                log_error "zsh not found in /etc/shells"
                if sudo -n true 2>/dev/null; then
                    log_info "Adding zsh to /etc/shells..."
                    echo "$ZSH_PATH" | sudo tee -a /etc/shells
                    chsh -s "$ZSH_PATH"
                    log_success "Default shell changed to zsh"
                else
                    log_warning "Cannot add zsh to /etc/shells without sudo privileges"
                fi
            fi
        else
            log_error "zsh not found"
            return 1
        fi
    fi
    
    log_warning "Please log out and log back in for the shell change to take effect"
}

# Main function
main() {
    log_info "Starting SSH machine setup..."
    
    detect_os_and_package_manager
    update_system
    load_package_definitions
    
    # Install base packages
    log_info "Installing base packages..."
    install_base_packages "$PKG_MANAGER"
    install_dependencies
    
    # Install and setup zsh
    install_oh_my_zsh
    install_zsh_plugins
    
    # Install vim-plug and tmux plugin manager
    install_vim_plug
    install_tpm
    
    # Setup dotfiles with stow
    setup_dotfiles
    
    # Create tmux sessionizer
    create_tmux_sessionizer
    
    # Change default shell to zsh
    change_shell_to_zsh
    
    log_success "SSH machine setup completed!"
    log_info "Please restart your terminal or run 'source ~/.zshrc' to apply changes"
    log_info "To use tmux sessionizer, add 'bindkey -s ^f \"~/bin/tmux-sessionizer\\n\"' to your .zshrc"
}

# Handle script interruption
trap 'log_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"
