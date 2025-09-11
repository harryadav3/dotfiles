#!/bin/bash
# Base packages required for both full system and SSH-only setups

# Development tools
DEV_PACKAGES=(
    'git'                # Version control
    'vim'                # Text editor
    'neovim'             # Modern text editor
    'tmux'               # Terminal multiplexer
    'stow'               # Symlink farm manager
    'fzf'                # Fuzzy finder
    'curl'               # URL retrieval utility
    'wget'               # File retrieval utility
)

# Shell and terminal utilities
SHELL_PACKAGES=(
    'zsh'                # Z shell
    'ranger'             # File manager for the terminal
)

# Helper functions for package installation
install_base_packages_apt() {
    sudo apt-get install -y "${DEV_PACKAGES[@]}" "${SHELL_PACKAGES[@]}"
}

install_base_packages_pacman() {
    sudo pacman -S --needed --noconfirm "${DEV_PACKAGES[@]}" "${SHELL_PACKAGES[@]}"
}

install_base_packages_dnf() {
    sudo dnf install -y "${DEV_PACKAGES[@]}" "${SHELL_PACKAGES[@]}"
}

install_base_packages_yum() {
    sudo yum install -y "${DEV_PACKAGES[@]}" "${SHELL_PACKAGES[@]}"
}

install_base_packages() {
    case "$1" in
        "apt")
            install_base_packages_apt
            ;;
        "pacman")
            install_base_packages_pacman
            ;;
        "dnf")
            install_base_packages_dnf
            ;;
        "yum")
            install_base_packages_yum
            ;;
        *)
            echo "Unsupported package manager: $1"
            return 1
            ;;
    esac
}
