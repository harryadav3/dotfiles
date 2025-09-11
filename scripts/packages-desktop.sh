#!/bin/bash
# Desktop environment packages for full system setup

# Window manager and display packages
WM_PACKAGES=(
    'i3status'           # Status bar
    'i3lock'             # Screen locker
    'dmenu'              # Application launcher
    'lightdm'            # Display manager
    'lightdm-gtk-greeter' # LightDM greeter
    'xorg-xinit'         # X server initialization
    'xorg-xinput'        # Input device configuration
    'xorg-xev'           # Input event viewer
    'xss-lock'           # X screen saver lock
)

# System utilities
SYSTEM_UTILITIES=(
    'networkmanager'      # Network connection manager
    'network-manager-applet' # Network manager tray icon
    'brightnessctl'      # Brightness control
    'dunst'              # Notification daemon
    'feh'                # Image viewer and wallpaper setter
    'flameshot'          # Screenshot tool
    'volumeicon'         # Volume control icon
    'pavucontrol'        # PulseAudio volume control
    'gnome-keyring'      # Keyring manager
    'seahorse'           # GUI for gnome-keyring
    'baobab'             # Disk usage analyzer
    'vlc'                # Media player
)

# Audio packages
AUDIO_PACKAGES=(
    'pipewire'           # Modern audio server
    'pipewire-alsa'      # ALSA support
    'pipewire-jack'      # JACK support
    'pipewire-pulse'     # PulseAudio support
    'wireplumber'        # Session manager for PipeWire
)

# File management
FILE_PACKAGES=(
    'thunar'             # File manager
    'thunar-archive-plugin' # Archive plugin
    'thunar-media-tags-plugin' # Media tags
    'thunar-volman'      # Removable media
    'gvfs'               # Virtual filesystem
)

# Fonts and themes
APPEARANCE_PACKAGES=(
    'arc-gtk-theme'      # GTK theme
    'arc-icon-theme'     # Icon theme
    'ttf-jetbrains-mono' # Monospace font
    'ttf-dejavu'         # DejaVu font
    'gtk-engine-murrine' # GTK2 engine
    'lxappearance'       # GTK theme switcher
)

# AUR packages
AUR_PACKAGES=(
    'google-chrome'      # Web browser
    'spotify'            # Music player
    'visual-studio-code-bin' # Code editor
    'albert'             # Application launcher
)

# Helper functions for package installation
install_desktop_packages_apt() {
    # Debian/Ubuntu-specific package names
    WM_PACKAGES_APT=(
        'i3status'
        'i3lock'
        'dmenu'
        'lightdm'
        'lightdm-gtk-greeter'
        'xinit'
        'xinput'
        'x11-utils'
        'xss-lock'
    )
    
    SYSTEM_UTILITIES_APT=(
        'network-manager'
        'network-manager-gnome'
        'brightnessctl'
        'dunst'
        'feh'
        'flameshot'
        'volumeicon-alsa'
        'pavucontrol'
        'gnome-keyring'
        'seahorse'
        'baobab'
        'vlc'
    )
    
    AUDIO_PACKAGES_APT=(
        'pipewire'
        'pipewire-alsa'
        'pipewire-jack'
        'pipewire-pulse'
        'wireplumber'
    )
    
    FILE_PACKAGES_APT=(
        'thunar'
        'thunar-archive-plugin'
        'thunar-media-tags-plugin'
        'thunar-volman'
        'gvfs'
    )
    
    APPEARANCE_PACKAGES_APT=(
        'arc-theme'
        'arc-icon-theme'
        'fonts-jetbrains-mono'
        'fonts-dejavu'
        'gtk2-engines-murrine'
        'lxappearance'
    )
    
    sudo apt-get install -y "${WM_PACKAGES_APT[@]}" "${SYSTEM_UTILITIES_APT[@]}" \
        "${AUDIO_PACKAGES_APT[@]}" "${FILE_PACKAGES_APT[@]}" "${APPEARANCE_PACKAGES_APT[@]}"
}

install_desktop_packages_pacman() {
    sudo pacman -S --needed --noconfirm "${WM_PACKAGES[@]}" "${SYSTEM_UTILITIES[@]}" \
        "${AUDIO_PACKAGES[@]}" "${FILE_PACKAGES[@]}" "${APPEARANCE_PACKAGES[@]}"
}

install_desktop_packages() {
    case "$1" in
        "apt")
            install_desktop_packages_apt
            ;;
        "pacman")
            install_desktop_packages_pacman
            ;;
        "dnf"|"yum")
            echo "Desktop package installation for dnf/yum not fully implemented"
            # Add implementation here if needed
            ;;
        *)
            echo "Unsupported package manager: $1"
            return 1
            ;;
    esac
}

install_aur_packages() {
    if command -v yay &> /dev/null; then
        yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"
    else
        echo "yay not found. Cannot install AUR packages."
        return 1
    fi
}
