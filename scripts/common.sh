#!/bin/bash
# Common functions library for dotfiles setup
# Provides utility functions used across setup scripts

# =============================================================================
# COLOR DEFINITIONS
# =============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Pinned upstream versions (bump deliberately after reviewing upstream changes)
OMZ_COMMIT="6010fb6260f359e71d99ba25f05f9215809b3ed2"
ZSH_AUTOSUGGESTIONS_REF="v0.7.1"
ZSH_SYNTAX_HIGHLIGHTING_REF="0.8.0"
ZSH_COMPLETIONS_REF="0.36.0"
TPM_REF="v3.1.0"
FZF_REF="v0.75.0"
VIM_PLUG_REF="0.15.0"
VIM_PLUG_SHA256="f2e856512c982063d0f4353744a29208e98fc622a474209e3a022969c974654a"
UV_VERSION="0.13.7"
UV_INSTALLER_SHA256="d263ee68314cf5bea36b08e6bd9e2c4563240d7adb73756cf33af5c199b92db4"

# Use sudo only when not already root (minimal servers/containers often lack sudo)
if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

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

# =============================================================================
# OS DETECTION
# =============================================================================

# Detect OS and package manager
detect_os() {
    log_info "Detecting operating system and package manager..."
    
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$NAME
        OS_ID=$ID
        
        case $ID in
            debian|ubuntu|pop|linuxmint|elementary)
                PKG_MANAGER="apt"
                log_success "Detected $OS_NAME with apt package manager"
                ;;
            arch|manjaro|endeavouros)
                PKG_MANAGER="pacman"
                log_success "Detected $OS_NAME with pacman package manager"
                ;;
            *)
                if command -v apt-get &> /dev/null; then
                    PKG_MANAGER="apt"
                    OS_NAME="Ubuntu/Debian"
                elif command -v pacman &> /dev/null; then
                    PKG_MANAGER="pacman"
                    OS_NAME="Arch Linux"
                else
                    log_error "Unsupported operating system: $OS_NAME"
                    log_error "This setup only supports Ubuntu/Debian and Arch Linux"
                    exit 1
                fi
                ;;
        esac
    else
        # Fallback detection method
        if command -v apt-get &> /dev/null; then
            PKG_MANAGER="apt"
            OS_NAME="Ubuntu/Debian"
        elif command -v pacman &> /dev/null; then
            PKG_MANAGER="pacman"
            OS_NAME="Arch Linux"
        else
            log_error "Could not detect package manager"
            log_error "This setup only supports Ubuntu/Debian and Arch Linux"
            exit 1
        fi
    fi
    
    export PKG_MANAGER
    export OS_NAME
    export OS_ID
}

# =============================================================================
# SYSTEM UPDATE
# =============================================================================

update_system() {
    log_info "Updating system packages..."
    
    case $PKG_MANAGER in
        "apt")
            $SUDO apt-get update
            ;;
        "pacman")
            # -Sy alone causes partial upgrades on Arch; always sync and upgrade together
            $SUDO pacman -Syu --noconfirm
            ;;
        *)
            log_error "Unknown package manager: $PKG_MANAGER"
            return 1
            ;;
    esac
    
    log_success "System packages updated"
}

# =============================================================================
# PINNED GIT CLONE
# =============================================================================

# Usage: clone_pinned <https-url> <tag-or-commit> <dest>
# Fetches exactly one ref over HTTPS so nothing floats on a moving branch.
clone_pinned() {
    local url=$1 ref=$2 dest=$3

    mkdir -p "$dest"
    if ! { git -C "$dest" init -q \
        && git -C "$dest" remote add origin "$url" \
        && git -C "$dest" fetch -q --depth 1 origin "$ref" \
        && git -C "$dest" checkout -q FETCH_HEAD; }; then
        rm -rf "${dest:?}"
        log_error "Failed to clone $url at $ref"
        return 1
    fi
}

# =============================================================================
# OH-MY-ZSH SETUP
# =============================================================================

install_oh_my_zsh() {
    log_info "Installing oh-my-zsh..."
    
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_warning "oh-my-zsh is already installed"
        return 0
    fi
    
    # Pinned clone instead of piping a remote install script into sh
    clone_pinned https://github.com/ohmyzsh/ohmyzsh.git "$OMZ_COMMIT" "$HOME/.oh-my-zsh"
    
    log_success "oh-my-zsh installed"
}

install_zsh_plugins() {
    log_info "Installing zsh plugins..."
    
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    local entry name url ref
    
    for entry in \
        "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions.git|$ZSH_AUTOSUGGESTIONS_REF" \
        "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting.git|$ZSH_SYNTAX_HIGHLIGHTING_REF" \
        "zsh-completions|https://github.com/zsh-users/zsh-completions.git|$ZSH_COMPLETIONS_REF"; do
        IFS='|' read -r name url ref <<< "$entry"
        if [ ! -d "$ZSH_CUSTOM/plugins/$name" ]; then
            clone_pinned "$url" "$ref" "$ZSH_CUSTOM/plugins/$name"
            log_success "$name installed"
        else
            log_warning "$name already installed"
        fi
    done
}

# =============================================================================
# VIM SETUP
# =============================================================================

# Usage: download_vim_plug <dest-path>; downloads the pinned release and verifies its SHA-256
download_vim_plug() {
    local dest=$1
    local tmp
    tmp="$(mktemp)"

    curl -fsSL --proto '=https' --tlsv1.2 -o "$tmp" \
        "https://raw.githubusercontent.com/junegunn/vim-plug/$VIM_PLUG_REF/plug.vim" \
        || { rm -f "$tmp"; log_error "Failed to download vim-plug"; return 1; }

    if ! echo "$VIM_PLUG_SHA256  $tmp" | sha256sum -c --status -; then
        rm -f "$tmp"
        log_error "vim-plug checksum mismatch; refusing to install"
        return 1
    fi

    mkdir -p "$(dirname "$dest")"
    mv "$tmp" "$dest"
}

install_vim_plug() {
    log_info "Installing vim-plug..."
    
    if [ -f "$HOME/.vim/autoload/plug.vim" ]; then
        log_warning "vim-plug is already installed"
        return 0
    fi
    
    download_vim_plug "$HOME/.vim/autoload/plug.vim"
    
    log_success "vim-plug installed"
}

install_neovim_plug() {
    log_info "Setting up LazyVim for neovim..."
    
    # LazyVim bootstraps itself via lazy.nvim in the config.
    # The config files are stowed from the dotfiles repo.
    # lazy.nvim will auto-install on first launch of nvim.
    
    log_success "LazyVim config will be linked via stow. Run nvim to bootstrap plugins."
}

# Install neovim from GitHub releases (latest stable)
install_neovim() {
    log_info "Installing Neovim from GitHub releases (latest stable)..."
    
    # Remove system neovim if installed (Ubuntu/Debian repo version is outdated)
    if command -v apt-get &> /dev/null && dpkg -l neovim &> /dev/null 2>&1; then
        log_info "Removing system neovim package..."
        $SUDO apt-get remove -y neovim 2>/dev/null || true
    elif command -v pacman &> /dev/null && pacman -Qi neovim &> /dev/null 2>&1; then
        log_info "Removing system neovim package..."
        $SUDO pacman -R --noconfirm neovim 2>/dev/null || true
    fi
    
    # Check if neovim is already installed in /opt
    if [ -x "/opt/nvim-linux-x86_64/bin/nvim" ]; then
        log_warning "Neovim is already installed at /opt/nvim-linux-x86_64"
        return 0
    fi
    
    # Download latest neovim release to a temp file (not the current directory)
    log_info "Downloading Neovim..."
    local tmp
    tmp="$(mktemp)"
    curl -fsSL --proto '=https' --tlsv1.2 -o "$tmp" \
        https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz \
        || { rm -f "$tmp"; log_error "Failed to download Neovim"; return 1; }
    
    # Remove old installation if exists
    $SUDO rm -rf /opt/nvim-linux-x86_64
    
    # Extract to /opt
    log_info "Extracting Neovim to /opt..."
    $SUDO tar -C /opt -xzf "$tmp"
    
    # Clean up downloaded tarball
    rm -f "$tmp"
    
    log_success "Neovim installed to /opt/nvim-linux-x86_64"
    log_info "PATH will be updated via .zshrc"
}

# =============================================================================
# TMUX SETUP
# =============================================================================

install_tpm() {
    log_info "Installing Tmux Plugin Manager (TPM)..."
    
    if [ -d "$HOME/.tmux/plugins/tpm" ]; then
        log_warning "TPM is already installed"
        return 0
    fi
    
    clone_pinned https://github.com/tmux-plugins/tpm.git "$TPM_REF" "$HOME/.tmux/plugins/tpm"
    
    log_success "TPM installed"
}

# =============================================================================
# STOW CONFIGURATION
# =============================================================================

link_configs() {
    local setup_type=$1  # "ssh" or "desktop"
    local script_dir=$2
    
    log_info "Linking configuration files using stow..."
    
    cd "$script_dir" || exit 1
    
    # nvim config is a git submodule; it is empty unless initialised
    if [ -f "$script_dir/.gitmodules" ] && [ -e "$script_dir/.git" ]; then
        log_info "Initialising git submodules..."
        git -C "$script_dir" submodule update --init --recursive
    fi
    
    # Common configs for both SSH and desktop
    local common_configs=(
        "zsh"
        "vim"
        "tmux"
        "ranger"
        "nvim"
    )
    
    # Desktop-specific configs
    local desktop_configs=(
        "i3"
        "kitty"
        "dunst"
    )
    
    # Backup existing configs
    backup_configs "${common_configs[@]}"
    if [ "$setup_type" = "desktop" ]; then
        backup_configs "${desktop_configs[@]}"
    fi
    
    # Stow common configs
    for config in "${common_configs[@]}"; do
        if [ -d "$script_dir/$config" ]; then
            log_info "Linking $config configuration..."
            stow -t "$HOME" "$config" || {
                log_warning "Could not stow $config (conflicting files in \$HOME?)"
            }
        fi
    done
    
    # Stow desktop configs if desktop setup
    if [ "$setup_type" = "desktop" ]; then
        for config in "${desktop_configs[@]}"; do
            if [ -d "$script_dir/$config" ]; then
                log_info "Linking $config configuration..."
                stow -t "$HOME" "$config" || {
                    log_warning "Could not stow $config (conflicting files in \$HOME?)"
                }
            fi
        done
    fi
    
    log_success "Configuration files linked"
}

backup_configs() {
    local configs=("$@")
    local backup_dir="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"
    local backed_up=false
    
    for config in "${configs[@]}"; do
        local config_paths=()
        
        case $config in
            zsh)
                config_paths=("$HOME/.zshrc")
                ;;
            vim)
                config_paths=("$HOME/.vimrc" "$HOME/.ideavimrc")
                ;;
            tmux)
                config_paths=("$HOME/.tmux.conf")
                ;;
            i3|kitty|dunst|ranger|nvim)
                config_paths=("$HOME/.config/$config")
                ;;
        esac
        
        for config_path in "${config_paths[@]}"; do
            if [ -e "$config_path" ] && [ ! -L "$config_path" ]; then
                if [ "$backed_up" = false ]; then
                    mkdir -p "$backup_dir"
                    chmod 700 "$backup_dir"
                    backed_up=true
                fi
                log_warning "Backing up existing $config_path to $backup_dir"
                mv "$config_path" "$backup_dir/"
            fi
        done
    done
    
    if [ "$backed_up" = true ]; then
        log_success "Existing configurations backed up to $backup_dir"
    fi
}

# =============================================================================
# CHANGE DEFAULT SHELL
# =============================================================================

change_shell_to_zsh() {
    log_info "Changing default shell to zsh..."
    
    local zsh_path
    zsh_path="$(command -v zsh || true)"
    
    if [ -z "$zsh_path" ]; then
        log_error "zsh is not installed"
        return 1
    fi
    
    if [ "$SHELL" = "$zsh_path" ]; then
        log_warning "Default shell is already zsh"
        return 0
    fi
    
    # chsh only accepts shells listed in /etc/shells
    if ! grep -qx "$zsh_path" /etc/shells; then
        echo "$zsh_path" | $SUDO tee -a /etc/shells > /dev/null
    fi
    
    chsh -s "$zsh_path" || {
        log_warning "Could not change shell automatically; run: chsh -s $zsh_path"
        return 0
    }
    log_success "Default shell changed to zsh (logout and login again for changes to take effect)"
}

# =============================================================================
# FZF SETUP
# =============================================================================

install_fzf_keybindings() {
    log_info "Installing fzf from GitHub..."
    
    # Remove system fzf if installed (Ubuntu/Debian repo version is outdated)
    if command -v apt-get &> /dev/null && dpkg -l fzf &> /dev/null 2>&1; then
        log_info "Removing system fzf package..."
        $SUDO apt-get remove -y fzf 2>/dev/null || true
    fi
    
    # Check if fzf is already installed
    if [ -d "$HOME/.fzf" ]; then
        log_warning "fzf directory already exists at ~/.fzf"
        
        # Check if fzf command is available
        if command -v fzf &> /dev/null; then
            log_success "fzf is already installed"
            return 0
        else
            log_warning "fzf directory exists but command not found, reinstalling..."
            rm -rf "${HOME:?}/.fzf"
        fi
    fi
    
    log_info "Cloning fzf repository..."
    clone_pinned https://github.com/junegunn/fzf.git "$FZF_REF" "$HOME/.fzf"
    
    # --bin only fetches the binary; .zshrc loads shell integration via `fzf --zsh`
    log_info "Running fzf installation script..."
    "$HOME/.fzf/install" --bin
    
    log_success "fzf installed successfully from GitHub"
}

# =============================================================================
# UV (PYTHON PACKAGE MANAGER) SETUP
# =============================================================================

install_uv() {
    log_info "Installing uv $UV_VERSION..."

    if [ -x "$HOME/.local/bin/uv" ] || command -v uv &> /dev/null; then
        log_warning "uv is already installed"
        return 0
    fi

    local tmp
    tmp="$(mktemp)"

    # Pinned installer verified by checksum instead of `curl | sh`; it installs the matching arch build
    curl -fsSL --proto '=https' --tlsv1.2 -o "$tmp" "https://astral.sh/uv/$UV_VERSION/install.sh" \
        || { rm -f "$tmp"; log_error "Failed to download uv installer"; return 1; }

    if ! echo "$UV_INSTALLER_SHA256  $tmp" | sha256sum -c --status -; then
        rm -f "$tmp"
        log_error "uv installer checksum mismatch; refusing to run it"
        return 1
    fi

    # PATH is already handled in .zshrc, so don't let the installer edit shell profiles
    UV_NO_MODIFY_PATH=1 sh "$tmp"
    rm -f "$tmp"

    log_success "uv installed to ~/.local/bin"
}

# =============================================================================
# DEBIAN/UBUNTU BINARY NAME FIXUPS
# =============================================================================

# Debian ships bat as `batcat` and fd as `fdfind`; expose the standard names
link_debian_binaries() {
    mkdir -p "$HOME/.local/bin"
    if command -v batcat &> /dev/null && ! command -v bat &> /dev/null; then
        ln -s "$(command -v batcat)" "$HOME/.local/bin/bat"
    fi
    if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
        ln -s "$(command -v fdfind)" "$HOME/.local/bin/fd"
    fi
}

# =============================================================================
# NEOVIM VERSION CHECK
# =============================================================================

# The nvim config (LazyVim) needs a recent Neovim; distro repos are often older
check_nvim_version() {
    command -v nvim &> /dev/null || return 0
    local ver
    ver="$(nvim --version | head -n1 | sed -E 's/^NVIM v([0-9]+\.[0-9]+).*/\1/')"
    if [ "$(printf '%s\n0.10\n' "$ver" | sort -V | head -n1)" != "0.10" ]; then
        log_warning "Neovim $ver is older than 0.10 required by the nvim config; install a newer release (https://github.com/neovim/neovim/releases)"
    fi
}
