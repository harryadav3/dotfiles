#!/bin/bash

# Dotfiles Setup Script
# Supports both SSH/Server and Desktop setups
# 
# Usage:
#   ./setup.sh --ssh      # Install minimal dev setup (zsh, vim, tmux, ranger, nvim)
#   ./setup.sh --desktop  # Install full desktop setup (includes i3, kitty, dunst + dev tools)
#   ./setup.sh --help     # Show help message

set -e  # Exit on any error

# =============================================================================
# SCRIPT CONFIGURATION
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETUP_TYPE=""

# =============================================================================
# LOAD COMMON FUNCTIONS AND PACKAGES
# =============================================================================

source "$SCRIPT_DIR/scripts/common.sh"
source "$SCRIPT_DIR/scripts/packages.sh"

# =============================================================================
# HELP MESSAGE
# =============================================================================

show_help() {
    cat << EOF
Dotfiles Setup Script

Usage:
    ./setup.sh [OPTIONS]

Options:
    --ssh       Install minimal SSH/Server setup
                Includes: zsh, vim, neovim, tmux, ranger, fzf, ripgrep, bat, git
                
    --desktop   Install full Desktop setup
                Includes: SSH setup + i3, kitty, dunst, and desktop environment
                
    --list      List all packages that would be installed
    
    --help      Show this help message

Examples:
    # Setup SSH machine with dev tools only
    ./setup.sh --ssh
    
    # Setup desktop with i3 window manager
    ./setup.sh --desktop
    
    # List all packages
    ./setup.sh --list

EOF
}

# =============================================================================
# MAIN SETUP FUNCTIONS
# =============================================================================

setup_ssh_machine() {
    log_info "Starting SSH/Server setup..."
    log_info "This will install: zsh, vim, neovim, tmux, ranger, fzf, ripgrep, bat, git"
    echo
    
    # Detect OS
    detect_os
    
    # Update system
    update_system
    
    # Install packages
    log_info "Installing SSH/Server packages..."
    install_ssh_packages "$PKG_MANAGER"
    
    # Install oh-my-zsh and plugins
    install_oh_my_zsh
    install_zsh_plugins
    
    # Install vim-plug
    install_vim_plug
    
    # Install neovim from GitHub releases
    install_neovim
    
    # Install TPM (Tmux Plugin Manager)
    install_tpm
    
    # Link configuration files
    link_configs "ssh" "$SCRIPT_DIR"
    
    # Setup fzf
    install_fzf_keybindings
    
    # Change default shell to zsh
    change_shell_to_zsh
    
    log_success "SSH/Server setup completed successfully!"
    echo
    log_info "Next steps:"
    log_info "1. Logout and login again (or restart your terminal)"
    log_info "2. Open vim and run :PlugInstall to install vim plugins"
    log_info "3. Open nvim to bootstrap LazyVim plugins"
    log_info "4. Open tmux and press prefix + I (capital i) to install tmux plugins"
    log_info "5. Your shell should now be zsh with oh-my-zsh"
}

setup_desktop() {
    log_info "Starting Desktop setup..."
    log_info "This will install: SSH tools + i3, kitty, dunst, and desktop environment"
    echo
    
    # Detect OS
    detect_os
    
    # Update system
    update_system
    
    # Install packages (includes SSH packages)
    log_info "Installing Desktop packages..."
    install_desktop_packages "$PKG_MANAGER"
    
    # Install oh-my-zsh and plugins
    install_oh_my_zsh
    install_zsh_plugins
    
    # Install vim-plug
    install_vim_plug
    
    # Install neovim from GitHub releases
    install_neovim
    
    # Install TPM (Tmux Plugin Manager)
    install_tpm
    
    # Link configuration files (including desktop configs + neovim)
    link_configs "desktop" "$SCRIPT_DIR"
    
    # Setup fzf
    install_fzf_keybindings
    
    # Change default shell to zsh
    change_shell_to_zsh
    
    log_success "Desktop setup completed successfully!"
    echo
    log_info "Next steps:"
    log_info "1. Logout and login again"
    log_info "2. Open vim and run :PlugInstall to install vim plugins"
    log_info "3. Open nvim and run :PlugInstall to install neovim plugins"
    log_info "4. Open tmux and press prefix + I (capital i) to install tmux plugins"
    log_info "5. At login screen, select i3 as your window manager"
    log_info "6. Your shell should now be zsh with oh-my-zsh"
}

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

if [ $# -eq 0 ]; then
    log_error "No arguments provided"
    echo
    show_help
    exit 1
fi

case "$1" in
    --ssh)
        SETUP_TYPE="ssh"
        setup_ssh_machine
        ;;
    --desktop)
        SETUP_TYPE="desktop"
        setup_desktop
        ;;
    --list)
        list_all_packages
        ;;
    --help|-h)
        show_help
        ;;
    *)
        log_error "Unknown option: $1"
        echo
        show_help
        exit 1
        ;;
esac
