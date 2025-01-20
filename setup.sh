#!/bin/bash

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo_step() {
    echo -e "${BLUE}==> ${1}${NC}"
}


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
    'fzf'
    'feh'                # Image viewer and wallpaper setter
    'flameshot'          # Screenshot tool
    'volumeicon'         # Volume control icon
    'pavucontrol'        # PulseAudio volume control
    'gnome-keyring'      # Keyring manager
    'seahorse'           # GUI for gnome-keyring
    'baobab'
)

# Audio packages
AUDIO_PACKAGES=(
    'pipewire'           # Modern audio server
    'pipewire-alsa'      # ALSA support
    'pipewire-jack'      # JACK support
    'pipewire-pulse'     # PulseAudio support
    'wireplumber'        # Session manager for PipeWire
)

# Development tools
DEV_PACKAGES=(
    'git'                # Version control
    'neovim'             # Text editor
    'gvim'               # GUI vim
    'tmux'               # Terminal multiplexer
    'stow'               # Symlink farm manager
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
    'ttf-dejavu'
    'gtk-engine-murrine' # GTK2 engine
    'lxappearance'       # GTK theme switcher
)

# AUR packages
AUR_PACKAGES=(
    'google-chrome'      # Web browser
    'spotify'            # Music player
    'visual-studio-code-bin' # Code editor
)

install_packages() {
    echo_step "Installing pacman packages..."
    sudo pacman -S --needed --noconfirm  "${WM_PACKAGES[@]}" \
        "${SYSTEM_UTILITIES[@]}" "${AUDIO_PACKAGES[@]}" "${DEV_PACKAGES[@]}" \
        "${FILE_PACKAGES[@]}" "${APPEARANCE_PACKAGES[@]}"
}

install_yay() {
    if ! command -v yay &> /dev/null; then
        echo_step "Installing yay..."
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        (cd /tmp/yay && makepkg -si --noconfirm)
        rm -rf /tmp/yay
    fi
}

install_aur_packages() {
    echo_step "Installing AUR packages..."
    yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"
}

setup_zsh() {
    echo_step "Setting up Zsh and Oh My Zsh..."
    # Install Zsh
    sudo pacman -S --needed --noconfirm zsh
    
    # Install Oh My Zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    # Set Zsh as default shell
    chsh -s $(which zsh)
}

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
}

main() {
    install_packages
    install_yay
    install_aur_packages
    setup_zsh
    setup_fonts
    
    echo_step "Setup completed! Please log out and back in for all changes to take effect."
}

# Run the script
main
