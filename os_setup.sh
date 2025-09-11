#!/bin/bash

# Full OS setup script - for systems with GUI and window manager
# This script installs and configures a complete desktop environment with i3, along with
# all necessary development tools, terminal utilities, and system applications.

set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'  # No Color

# Echo with color and prefix
echo_step() {
    echo -e "${BLUE}==> ${1}${NC}"
}

echo_success() {
    echo -e "${GREEN}==> ${1}${NC}"
}

echo_warning() {
    echo -e "${YELLOW}==> ${1}${NC}"
}

echo_error() {
    echo -e "${RED}==> ${1}${NC}"
}

# Detect OS and package manager
detect_os_and_package_manager() {
    echo_step "Detecting operating system and package manager..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$NAME
        OS_ID=$ID
        
        case $ID in
            debian|ubuntu|pop|linuxmint|elementary)
                PKG_MANAGER="apt"
                echo_success "Detected $OS_NAME with apt package manager"
                ;;
            arch|manjaro|endeavouros)
                PKG_MANAGER="pacman"
                echo_success "Detected $OS_NAME with pacman package manager"
                ;;
            fedora)
                PKG_MANAGER="dnf"
                echo_success "Detected $OS_NAME with dnf package manager"
                ;;
            centos|rhel)
                PKG_MANAGER="yum"
                echo_success "Detected $OS_NAME with yum package manager"
                ;;
            *)
                echo_error "Unsupported operating system: $OS_NAME"
                exit 1
                ;;
        esac
    else
        echo_error "Could not detect operating system"
        exit 1
    fi
}

# Update system
update_system() {
    echo_step "Updating system packages..."
    
    case $PKG_MANAGER in
        apt)
            sudo apt-get update
            sudo apt-get upgrade -y
            ;;
        pacman)
            sudo pacman -Syu --noconfirm
            ;;
        dnf)
            sudo dnf update -y
            ;;
        yum)
            sudo yum update -y
            ;;
    esac
    
    echo_success "System updated"
}

# Load package definitions
load_package_definitions() {
    echo_step "Loading package definitions..."
    
    # Source the package definition files
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    if [ -f "$SCRIPT_DIR/scripts/packages-base.sh" ]; then
        source "$SCRIPT_DIR/scripts/packages-base.sh"
        echo_success "Loaded base packages"
    else
        echo_error "Base packages file not found"
        exit 1
    fi
    
    if [ -f "$SCRIPT_DIR/scripts/packages-desktop.sh" ]; then
        source "$SCRIPT_DIR/scripts/packages-desktop.sh"
        echo_success "Loaded desktop packages"
    else
        echo_error "Desktop packages file not found"
        exit 1
    fi
}

# Install yay (AUR helper for Arch-based systems)
install_yay() {
    if [[ "$PKG_MANAGER" == "pacman" ]]; then
        echo_step "Checking for yay (AUR helper)..."
        
        if ! command -v yay &> /dev/null; then
            echo_step "Installing yay..."
            sudo pacman -S --needed --noconfirm git base-devel
            git clone https://aur.archlinux.org/yay.git /tmp/yay
            (cd /tmp/yay && makepkg -si --noconfirm)
            rm -rf /tmp/yay
            echo_success "yay installed"
        else
            echo_warning "yay is already installed"
        fi
    fi
}

# Setup zsh
setup_zsh() {
    echo_step "Setting up Zsh and Oh My Zsh..."
    
    # Install Oh My Zsh if not already installed
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        echo_success "Oh My Zsh installed"
    else
        echo_warning "Oh My Zsh is already installed"
    fi
    
    # Install zsh plugins
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    fi
    
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    fi
    
    # Set Zsh as default shell
    if [[ "$SHELL" != *"zsh"* ]]; then
        echo_step "Setting zsh as default shell..."
        chsh -s $(which zsh)
    fi
}

# Setup system fonts
setup_fonts() {
    echo_step "Setting up system fonts..."
    
    # Create font configuration
    mkdir -p ~/.config/fontconfig
    cat > ~/.config/fontconfig/fonts.conf << 'EOF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
    <match target="font">
        <edit name="antialias" mode="assign">
            <bool>true</bool>
        </edit>
        <edit name="hinting" mode="assign">
            <bool>true</bool>
        </edit>
        <edit name="hintstyle" mode="assign">
            <const>hintslight</const>
        </edit>
        <edit name="rgba" mode="assign">
            <const>rgb</const>
        </edit>
        <edit name="lcdfilter" mode="assign">
            <const>lcddefault</const>
        </edit>
    </match>
    <alias>
        <family>sans-serif</family>
        <prefer>
            <family>Noto Sans</family>
        </prefer>
    </alias>
    <alias>
        <family>serif</family>
        <prefer>
            <family>Noto Serif</family>
        </prefer>
    </alias>
    <alias>
        <family>monospace</family>
        <prefer>
            <family>JetBrains Mono</family>
        </prefer>
    </alias>
</fontconfig>
EOF

    echo_success "Font configuration set up"
}

# Setup dotfiles using stow
setup_dotfiles() {
    echo_step "Setting up dotfiles using stow..."
    
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
    
    # Get the script directory
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # Stow each configuration directory
    for dir in "$SCRIPT_DIR"/*/; do
        dir_name=$(basename "$dir")
        
        # Skip the scripts directory and any other non-config directories
        if [[ "$dir_name" == "scripts" || "$dir_name" == ".git" ]]; then
            continue
        fi
        
        echo_step "Stowing $dir_name..."
        stow -v -R -t "$HOME" "$dir_name"
    done
    
    echo_success "Dotfiles set up"
}

# Main function
main() {
    echo_step "Starting full OS setup..."
    
    detect_os_and_package_manager
    update_system
    load_package_definitions
    
    # Install base packages
    echo_step "Installing base packages..."
    install_base_packages "$PKG_MANAGER"
    
    # Install desktop packages
    echo_step "Installing desktop environment packages..."
    install_desktop_packages "$PKG_MANAGER"
    
    # For Arch-based systems, install AUR packages
    if [[ "$PKG_MANAGER" == "pacman" ]]; then
        install_yay
        echo_step "Installing AUR packages..."
        install_aur_packages
    fi
    
    setup_zsh
    setup_fonts
    setup_dotfiles
    
    echo_success "Full OS setup completed! Please log out and back in for all changes to take effect."
}

# Run the script
main
