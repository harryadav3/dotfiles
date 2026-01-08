#!/bin/bash
# Centralized package definitions for dotfiles setup
# All packages are defined here with clear categorization

# =============================================================================
# CORE DEV PACKAGES (Required for SSH/Server setup)
# =============================================================================

# Essential development tools
DEV_PACKAGES=(
    'git'                # Version control
    'vim'                # Text editor
    'neovim'             # Modern text editor
    'tmux'               # Terminal multiplexer
    'stow'               # Symlink farm manager
    'curl'               # URL retrieval utility
    'wget'               # File retrieval utility
    'ripgrep'            # Fast grep alternative (rg)
    'bat'                # Cat with syntax highlighting
)

# Shell and terminal utilities
SHELL_PACKAGES=(
    'zsh'                # Z shell
    'ranger'             # File manager for the terminal
)

# Build dependencies (needed for compiling tools)
BUILD_DEPS_APT=(
    'build-essential'
    'software-properties-common'
    'pkg-config'
    'libssl-dev'
)

BUILD_DEPS_PACMAN=(
    'base-devel'
    'openssl'
)

# =============================================================================
# DESKTOP PACKAGES (Only for desktop setup with i3)
# =============================================================================

# i3 window manager and related
I3_PACKAGES=(
    'i3-wm'              # i3 window manager
    'i3status'           # Status bar
    'i3lock'             # Screen locker
    'dmenu'              # Application launcher
)

# Display and X11
XORG_PACKAGES=(
    'xorg-server'        # X server (pacman)
    'xorg-xinit'         # X server initialization
    'xorg-xinput'        # Input device configuration
    'xorg-xev'           # Input event viewer
    'lightdm'            # Display manager
    'lightdm-gtk-greeter' # LightDM greeter
    'xss-lock'           # X screen saver lock
    'arandr'             # GUI for xrandr
)

XORG_PACKAGES_APT=(
    'xorg'               # X server (apt)
    'xinit'              # X initialization
    'xinput'             # Input configuration
    'x11-utils'          # X utilities
    'lightdm'            # Display manager
    'lightdm-gtk-greeter' # LightDM greeter
    'xss-lock'           # Screen saver lock
    'arandr'             # GUI for xrandr
)

# Terminal emulator
TERMINAL_PACKAGES=(
    'kitty'              # GPU-accelerated terminal
)

# Desktop system utilities
DESKTOP_UTILITIES=(
    'dunst'              # Notification daemon
    'feh'                # Image viewer and wallpaper setter
    'flameshot'          # Screenshot tool
    'rofi'               # Application launcher (alternative to dmenu)
    'picom'              # Compositor
    'nitrogen'           # Wallpaper setter
    'lxappearance'       # GTK theme switcher
)

# Network management
NETWORK_PACKAGES=(
    'networkmanager'      # Network connection manager
    'network-manager-applet' # Network manager tray icon
)

NETWORK_PACKAGES_APT=(
    'network-manager'
    'network-manager-gnome'
)

# Audio packages
AUDIO_PACKAGES=(
    'pipewire'           # Modern audio server
    'pipewire-alsa'      # ALSA support
    'pipewire-jack'      # JACK support
    'pipewire-pulse'     # PulseAudio support
    'wireplumber'        # Session manager for PipeWire
    'pavucontrol'        # PulseAudio volume control
)

# Brightness and power
POWER_PACKAGES=(
    'brightnessctl'      # Brightness control
)

# File management
FILE_PACKAGES=(
    'thunar'             # File manager
    'thunar-archive-plugin' # Archive plugin
    'gvfs'               # Virtual filesystem
)

FILE_PACKAGES_APT=(
    'thunar'
    'thunar-archive-plugin'
    'thunar-media-tags-plugin'
    'thunar-volman'
    'gvfs'
)

# Fonts and themes
APPEARANCE_PACKAGES=(
    'ttf-jetbrains-mono' # Monospace font
    'ttf-dejavu'         # DejaVu font
    'arc-gtk-theme'      # GTK theme
    'arc-icon-theme'     # Icon theme
    'gtk-engine-murrine' # GTK2 engine
)

APPEARANCE_PACKAGES_APT=(
    'fonts-jetbrains-mono'
    'fonts-dejavu'
    'arc-theme'
    'arc-icon-theme'
    'gtk2-engines-murrine'
)

# =============================================================================
# PACKAGE INSTALLATION FUNCTIONS
# =============================================================================

# Install SSH/Server packages (core dev tools only)
install_ssh_packages() {
    local pkg_manager=$1
    
    case $pkg_manager in
        "apt")
            echo "Installing packages for Ubuntu/Debian..."
            sudo apt-get update
            sudo apt-get install -y \
                "${DEV_PACKAGES[@]}" \
                "${SHELL_PACKAGES[@]}" \
                "${BUILD_DEPS_APT[@]}"
            ;;
        "pacman")
            echo "Installing packages for Arch Linux..."
            sudo pacman -Sy
            sudo pacman -S --needed --noconfirm \
                "${DEV_PACKAGES[@]}" \
                "${SHELL_PACKAGES[@]}" \
                "${BUILD_DEPS_PACMAN[@]}"
            ;;
        *)
            echo "Unsupported package manager: $pkg_manager"
            return 1
            ;;
    esac
}

# Install Desktop packages (includes SSH packages + desktop environment)
install_desktop_packages() {
    local pkg_manager=$1
    
    # First install SSH packages
    install_ssh_packages "$pkg_manager"
    
    case $pkg_manager in
        "apt")
            echo "Installing desktop packages for Ubuntu/Debian..."
            sudo apt-get install -y \
                i3 \
                "${XORG_PACKAGES_APT[@]}" \
                "${TERMINAL_PACKAGES[@]}" \
                "${DESKTOP_UTILITIES[@]}" \
                "${NETWORK_PACKAGES_APT[@]}" \
                "${AUDIO_PACKAGES[@]}" \
                "${POWER_PACKAGES[@]}" \
                "${FILE_PACKAGES_APT[@]}" \
                "${APPEARANCE_PACKAGES_APT[@]}"
            ;;
        "pacman")
            echo "Installing desktop packages for Arch Linux..."
            sudo pacman -S --needed --noconfirm \
                "${I3_PACKAGES[@]}" \
                "${XORG_PACKAGES[@]}" \
                "${TERMINAL_PACKAGES[@]}" \
                "${DESKTOP_UTILITIES[@]}" \
                "${NETWORK_PACKAGES[@]}" \
                "${AUDIO_PACKAGES[@]}" \
                "${POWER_PACKAGES[@]}" \
                "${FILE_PACKAGES[@]}" \
                "${APPEARANCE_PACKAGES[@]}"
            ;;
        *)
            echo "Unsupported package manager: $pkg_manager"
            return 1
            ;;
    esac
}

# List all packages for review
list_all_packages() {
    echo "=== CORE DEV PACKAGES (SSH Setup) ==="
    echo "Development tools:"
    printf '%s\n' "${DEV_PACKAGES[@]}"
    echo
    echo "Shell utilities:"
    printf '%s\n' "${SHELL_PACKAGES[@]}"
    echo
    
    echo "=== DESKTOP PACKAGES (Desktop Setup) ==="
    echo "i3 Window Manager:"
    printf '%s\n' "${I3_PACKAGES[@]}"
    echo
    echo "Terminal:"
    printf '%s\n' "${TERMINAL_PACKAGES[@]}"
    echo
    echo "Desktop Utilities:"
    printf '%s\n' "${DESKTOP_UTILITIES[@]}"
    echo
    echo "Audio:"
    printf '%s\n' "${AUDIO_PACKAGES[@]}"
    echo
    echo "Appearance:"
    printf '%s\n' "${APPEARANCE_PACKAGES[@]}"
    echo
}
