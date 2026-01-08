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
            sudo apt-get update
            ;;
        "pacman")
            sudo pacman -Sy
            ;;
        *)
            log_error "Unknown package manager: $PKG_MANAGER"
            return 1
            ;;
    esac
    
    log_success "System packages updated"
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
    
    # Install oh-my-zsh without prompting
    export RUNZSH=no
    export KEEP_ZSHRC=yes
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    
    log_success "oh-my-zsh installed"
}

install_zsh_plugins() {
    log_info "Installing zsh plugins..."
    
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    
    # Install zsh-autosuggestions
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
        log_success "zsh-autosuggestions installed"
    else
        log_warning "zsh-autosuggestions already installed"
    fi
    
    # Install zsh-syntax-highlighting
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
        log_success "zsh-syntax-highlighting installed"
    else
        log_warning "zsh-syntax-highlighting already installed"
    fi
    
    # Install zsh-completions
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]; then
        git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions"
        log_success "zsh-completions installed"
    else
        log_warning "zsh-completions already installed"
    fi
}

# =============================================================================
# VIM SETUP
# =============================================================================

install_vim_plug() {
    log_info "Installing vim-plug..."
    
    if [ -f "$HOME/.vim/autoload/plug.vim" ]; then
        log_warning "vim-plug is already installed"
        return 0
    fi
    
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    
    log_success "vim-plug installed"
}

install_neovim_plug() {
    log_info "Installing vim-plug for neovim..."
    
    local nvim_plug_path="$HOME/.local/share/nvim/site/autoload/plug.vim"
    
    if [ -f "$nvim_plug_path" ]; then
        log_warning "vim-plug for neovim is already installed"
        return 0
    fi
    
    curl -fLo "$nvim_plug_path" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    
    log_success "vim-plug for neovim installed"
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
    
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    
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
            stow -t "$HOME" "$config" 2>/dev/null || {
                log_warning "Could not stow $config (might already exist)"
            }
        fi
    done
    
    # Stow desktop configs if desktop setup
    if [ "$setup_type" = "desktop" ]; then
        for config in "${desktop_configs[@]}"; do
            if [ -d "$script_dir/$config" ]; then
                log_info "Linking $config configuration..."
                stow -t "$HOME" "$config" 2>/dev/null || {
                    log_warning "Could not stow $config (might already exist)"
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
        local config_path=""
        
        case $config in
            zsh)
                config_path="$HOME/.zshrc"
                ;;
            vim)
                config_path="$HOME/.vimrc"
                ;;
            tmux)
                config_path="$HOME/.tmux.conf"
                ;;
            i3|kitty|dunst|ranger|nvim)
                config_path="$HOME/.config/$config"
                ;;
        esac
        
        if [ -n "$config_path" ] && [ -e "$config_path" ] && [ ! -L "$config_path" ]; then
            if [ "$backed_up" = false ]; then
                mkdir -p "$backup_dir"
                backed_up=true
            fi
            log_warning "Backing up existing $config configuration to $backup_dir"
            mv "$config_path" "$backup_dir/"
        fi
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
    
    if [ "$SHELL" = "$(which zsh)" ]; then
        log_warning "Default shell is already zsh"
        return 0
    fi
    
    if command -v zsh &> /dev/null; then
        chsh -s "$(which zsh)"
        log_success "Default shell changed to zsh (logout and login again for changes to take effect)"
    else
        log_error "zsh is not installed"
        return 1
    fi
}

# =============================================================================
# FZF SETUP
# =============================================================================

install_fzf_keybindings() {
    log_info "Installing fzf from GitHub..."
    
    # Check if fzf is already installed
    if [ -d "$HOME/.fzf" ]; then
        log_warning "fzf directory already exists at ~/.fzf"
        
        # Check if fzf command is available
        if command -v fzf &> /dev/null; then
            log_success "fzf is already installed"
            return 0
        else
            log_warning "fzf directory exists but command not found, reinstalling..."
            rm -rf "$HOME/.fzf"
        fi
    fi
    
    # Clone fzf from GitHub
    log_info "Cloning fzf repository..."
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    
    # Run fzf install script (with auto-accept for all prompts)
    log_info "Running fzf installation script..."
    ~/.fzf/install --all
    
    log_success "fzf installed successfully from GitHub"
}
