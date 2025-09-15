#!/bin/bash

# Setup script for SSH machine with zsh, vim, and tmux configurations
# This script installs and configures zsh with oh-my-zsh, vim with plugins, and tmux with plugins

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

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_warning "This script should not be run as root for user configurations"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
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
        "brew")
            $INSTALL_CMD curl wget git
            ;;
    esac
    
    log_success "Basic dependencies installed"
}

# Install zsh
install_zsh() {
    log_info "Installing zsh..."
    
    if command -v zsh &> /dev/null; then
        log_warning "zsh is already installed"
    else
        case $PKG_MANAGER in
            "apt")
                $INSTALL_CMD zsh
                ;;
            "yum"|"dnf")
                $INSTALL_CMD zsh
                ;;
            "pacman")
                $INSTALL_CMD zsh
                ;;
            "brew")
                $INSTALL_CMD zsh
                ;;
        esac
        log_success "zsh installed"
    fi
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
    
    # Customize robbyrussell theme to show directory and machine indicator
    modify_zsh_theme
}

# Modify robbyrussell zsh theme to show directory name and machine indicator
modify_zsh_theme() {
    log_info "Customizing robbyrussell zsh theme..."
    
    ZSH_THEME_FILE="$HOME/.oh-my-zsh/themes/robbyrussell.zsh-theme"
    
    if [ -f "$ZSH_THEME_FILE" ]; then
        # Backup original theme file
        cp "$ZSH_THEME_FILE" "${ZSH_THEME_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Replace the PROMPT line with our custom one
        sed -i 's/PROMPT=.*/PROMPT="%(?:%{$fg_bold[green]%}%1{➜%} :%{$fg_bold[red]%}%1{➜%} ) %{$fg[cyan]%}%d %{$fg[yellow]%}(A6000)%{$reset_color%} -> "/' "$ZSH_THEME_FILE"
        
        log_success "robbyrussell zsh theme customized"
    else
        log_error "robbyrussell zsh theme file not found"
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

# Setup zsh configuration
setup_zsh_config() {
    log_info "Setting up zsh configuration..."
    
    # Backup existing .zshrc if it exists
    if [ -f "$HOME/.zshrc" ]; then
        cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backed up existing .zshrc"
    fi
    
    # Create .zshrc configuration
    cat > "$HOME/.zshrc" << 'EOF'
#to enable vim binding in the terminal 
#bindkey -v
set -o vi

#this is the fzf confuguration file 
eval "$(fzf --zsh)"

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

bindkey -s ^f "exec ~/tmux-sessionizer\n"
# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# <<< conda initialize <<<


alias ccc="cd ~/coding"
alias cca="cd ~/coding/ai-ml/"


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


# Start keychain and add SSH key
#eval $(keychain --quiet --eval --agents ssh id_ed25519)
#
#eval "$(ssh-agent -s)"
EOF
    
    log_success "zsh configuration created"
}

# Install fzf
install_fzf() {
    log_info "Installing fzf..."
    
    if command -v fzf &> /dev/null; then
        log_warning "fzf is already installed"
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
        ~/.fzf/install --all
        log_success "fzf installed"
    fi
}

# Install vim
install_vim() {
    log_info "Installing vim..."
    
    if command -v vim &> /dev/null; then
        log_warning "vim is already installed"
    else
        case $PKG_MANAGER in
            "apt")
                $INSTALL_CMD vim
                ;;
            "yum"|"dnf")
                $INSTALL_CMD vim
                ;;
            "pacman")
                $INSTALL_CMD vim
                ;;
            "brew")
                $INSTALL_CMD vim
                ;;
        esac
        log_success "vim installed"
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

# Setup vim configuration
setup_vim_config() {
    log_info "Setting up vim configuration..."
    
    # Backup existing .vimrc if it exists
    if [ -f "$HOME/.vimrc" ]; then
        cp "$HOME/.vimrc" "$HOME/.vimrc.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backed up existing .vimrc"
    fi
    
    # Create .vimrc configuration
    cat > "$HOME/.vimrc" << 'EOF'
" FAST MINIMAL STRONG VIMRC - Essential plugins and settings for Python/Rust/C
" Optimized for fast startup
" =============================================================================

" Basic Settings (keeping your existing ones)
set scrolloff=8
set number
set relativenumber
set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab
set smartindent
set guicursor=n-v-c:block,i-ci:ver25,r-cr:hor20,o:hor50

" Additional essential settings
set hidden                      " Allow switching buffers without saving
set nowrap                      " Don't wrap lines (MAIN FIX!)
set display=lastline            " Show partial last line instead of @@@
set sidescroll=1               " Smooth horizontal scrolling
set sidescrolloff=5            " Keep 5 chars visible when scrolling
set ignorecase                  " Case insensitive search
set smartcase                   " Case sensitive if uppercase present
set incsearch                   " Incremental search
set hlsearch                    " Highlight search results
set noswapfile                  " Disable swap files
set nobackup                    " Disable backup files
set undodir=~/.vim/undodir      " Undo directory
set undofile                    " Persistent undo
set signcolumn=no               " DISABLE signcolumn
set updatetime=50               " Faster completion
set wildmenu                    " Command completion
set wildmode=longest:full,full  " Command completion mode
set lazyredraw                  " Don't redraw while executing macros (faster)
set ttyfast                     " Fast terminal connection

" Performance improvements
set regexpengine=1             " Use old regexp engine (faster for some patterns)
set synmaxcol=200             " Don't syntax highlight long lines

" Install vim-plug if not present (OPTIMIZED - no autocmd)
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  echo "vim-plug installed. Please restart vim and run :PlugInstall"
  finish
endif

" Plugins (OPTIMIZED - lazy loading where possible)
call plug#begin('~/.vim/plugged')

" Essential plugins with lazy loading
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-fugitive', { 'on': ['Git', 'Gstatus', 'Gblame', 'Gdiff'] }
Plug 'tpope/vim-commentary'
Plug 'tpope/vim-surround'
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
Plug 'preservim/nerdtree', { 'on': ['NERDTreeToggle', 'NERDTreeFind'] }
Plug 'jiangmiao/auto-pairs'

" Language support (lazy loaded by filetype)
Plug 'rust-lang/rust.vim', { 'for': 'rust' }
Plug 'davidhalter/jedi-vim', { 'for': 'python' }

" MUCH LIGHTER alternative to ale and vim-polyglot
" Only load basic syntax highlighting instead of heavy plugins
Plug 'sheerun/vim-polyglot'
" Remove ALE completely for now - it's a major slowdown
" We'll use basic vim features instead

" Color scheme - GitHub dark theme only
Plug 'vv9k/vim-github-dark'           " GitHub dark theme for Vim

call plug#end()

" Color scheme configuration
set background=dark

" Set terminal to use true colors (important for proper colors)
if (has("termguicolors"))
    set termguicolors
endif

" Use GitHub dark theme - fallback to default if not available
silent! colorscheme ghdark

" Make background completely black like terminal (uncomment if desired)
" highlight Normal guibg=#000000 ctermbg=black
" highlight NonText guibg=#000000 ctermbg=black
" highlight SignColumn guibg=#000000 ctermbg=black
" highlight LineNr guibg=#000000 ctermbg=black
" highlight CursorLineNr guibg=#000000 ctermbg=black
" highlight VertSplit guibg=#000000 ctermbg=black
" highlight RelativeLineNr guibg=#000000 ctermbg=black ctermfg=darkgray guifg=#404040

" Leader key
let mapleader = " "

" Your existing keymaps
nnoremap <leader>pv :Vex<CR>
nnoremap <leader>e :Ex<CR>
vnoremap <leader>p "_dP
vnoremap <leader>y "+y
nnoremap <leader>x :!chmod +x %<CR>
nnoremap <leader>y "+y
vnoremap <leader>y "+y
nnoremap <leader>Y "+Y

" Additional essential keymaps
nnoremap <leader>h :nohlsearch<CR>
nnoremap <C-p> :Files<CR>
nnoremap <leader>fg :GFiles<CR>
nnoremap <leader>fb :Buffers<CR>
nnoremap <leader>fr :Rg<CR>
nnoremap <leader>/ :BLines<CR>

" NERDTree (lazy loaded)
nnoremap <leader>n :NERDTreeToggle<CR>
nnoremap <leader>nf :NERDTreeFind<CR>

" Window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Buffer navigation
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprevious<CR>
nnoremap <leader>bd :bdelete<CR>

" Quick save and quit
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>

" Plugin Configuration

" FZF
let g:fzf_layout = { 'down': '~40%' }
let g:fzf_preview_window = ['right:50%']

" Airline (lightweight status line config)
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 0  " Disable powerline fonts for speed
" Fix airline theme issues
let g:airline_theme_patch_func = 'AirlineThemePatch'
function! AirlineThemePatch(palette)
  " Simple fix for missing theme elements
  if !has_key(a:palette, 'inactive')
    let a:palette.inactive = a:palette.normal
  endif
endfunction

" Rust configuration (only loads when editing rust files)
let g:rustfmt_autosave = 1

" Python configuration (only loads when editing python files)
let g:jedi#use_splits_not_buffers = "right"
let g:jedi#show_call_signatures = "1"
" Make jedi faster
let g:jedi#popup_on_dot = 0
let g:jedi#popup_select_first = 0

" REMOVED ALE COMPLETELY - it was the main cause of slowdown
" Instead, use vim's built-in features:
" - :make for building
" - :copen for quickfix list
" - Manual formatting commands

" Auto-commands (OPTIMIZED - fewer autocmds)
augroup general
    autocmd!
    " Return to last edit position
    autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
augroup END

" Language specific settings (ONLY when needed)
augroup languages
    autocmd!
    autocmd FileType python setlocal tabstop=4 shiftwidth=4
    autocmd FileType rust setlocal tabstop=4 shiftwidth=4
    autocmd FileType c,cpp setlocal tabstop=2 shiftwidth=2
augroup END


EOF
    
    # Create the undo directory
    mkdir -p "$HOME/.vim/undodir"
    
    log_success "vim configuration created"
}

# Install vim plugins and dependencies
install_vim_plugins() {
    log_info "Installing vim plugins and dependencies..."
    
    # Create required directories
    mkdir -p "$HOME/.vim/undodir"
    
    # Install additional dependencies for plugins
    case $PKG_MANAGER in
        "apt")
            $INSTALL_CMD ripgrep fd-find
            ;;
        "yum"|"dnf")
            $INSTALL_CMD ripgrep fd-find
            ;;
        "pacman")
            $INSTALL_CMD ripgrep fd
            ;;
        "brew")
            $INSTALL_CMD ripgrep fd
            ;;
    esac
    
    # Install required npm packages for some plugins
    if command -v npm &> /dev/null; then
        npm install -g neovim
    fi
    
    # Install plugins using vim-plug
    vim +PlugInstall +qall
    
    # Install specific vim plugins not covered by vim-plug
    log_info "Installing specific vim plugins and themes..."
    
    # Install vim-github-dark theme if not already installed
    if [ ! -d "$HOME/.vim/plugged/vim-github-dark" ]; then
        git clone https://github.com/vv9k/vim-github-dark.git "$HOME/.vim/plugged/vim-github-dark"
    fi
    
    log_success "vim plugins and dependencies installed"
}

# Install tmux
install_tmux() {
    log_info "Installing tmux..."
    
    if command -v tmux &> /dev/null; then
        log_warning "tmux is already installed"
    else
        case $PKG_MANAGER in
            "apt")
                $INSTALL_CMD tmux
                ;;
            "yum"|"dnf")
                $INSTALL_CMD tmux
                ;;
            "pacman")
                $INSTALL_CMD tmux
                ;;
            "brew")
                $INSTALL_CMD tmux
                ;;
        esac
        log_success "tmux installed"
    fi
    
    # Install xclip for clipboard functionality
    case $PKG_MANAGER in
        "apt")
            $INSTALL_CMD xclip
            ;;
        "yum"|"dnf")
            $INSTALL_CMD xclip
            ;;
        "pacman")
            $INSTALL_CMD xclip
            ;;
        "brew")
            # macOS uses pbcopy/pbpaste
            ;;
    esac
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

# Setup tmux configuration
setup_tmux_config() {
    log_info "Setting up tmux configuration..."
    
    # Backup existing .tmux.conf if it exists
    if [ -f "$HOME/.tmux.conf" ]; then
        cp "$HOME/.tmux.conf" "$HOME/.tmux.conf.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backed up existing .tmux.conf"
    fi
    
    # Create .tmux.conf configuration
    cat > "$HOME/.tmux.conf" << 'EOF'
set -g  default-terminal "screen-256color"

# Set the prefix key to C-a
set -g prefix C-o
unbind C-b
bind C-o send-prefix

unbind %
bind , split-window -h 
bind / split-window -h 

unbind '"'
bind - split-window -v

unbind r
bind r source-file ~/.tmux.conf \; display "Reloaded!"

bind-key x kill-pane



bind -r j resize-pane -D 5
bind -r k resize-pane -U 5
bind -r l resize-pane -R 5
bind -r h resize-pane -L 5

set -g mouse on

set-window-option -g mode-keys vi

#screen time lage
set -s escape-time 0

#start the window with 1
set -g base-index 1

bind-key -T copy-mode-vi 'v' send -X begin-selection
# bind-key -T copy-mode-vi 'y' send -X copy-selection
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel 'xclip -in -selection clipboard'

unbind -T copy-mode-vi MouseDragEnd1Pane
#tmuxplugin

set -g @plugin 'tmux-plugins/tpm'

set -g @plugin 'christoomey/vim-tmux-navigator'

#theme

set -g @plugin 'jimeh/tmux-themepack'

set -g @themepack 'powerline/block/cyan'


run '~/.tmux/plugins/tpm/tpm'
EOF
    
    log_success "tmux configuration created"
}

# Install tmux plugins
install_tmux_plugins() {
    log_info "Installing tmux plugins..."
    
    # Source tmux config and install plugins
    if command -v tmux &> /dev/null; then
        # Start a new tmux session in detached mode and install plugins
        tmux new-session -d -s plugin_install
        tmux send-keys -t plugin_install "~/.tmux/plugins/tpm/scripts/install_plugins.sh" Enter
        sleep 5  # Give it some time to install
        tmux kill-session -t plugin_install
        log_success "tmux plugins installed"
    else
        log_error "tmux not found, cannot install plugins"
        return 1
    fi
}

# Create tmux sessionizer script
create_tmux_sessionizer() {
    log_info "Creating tmux sessionizer script..."
    
    cat > "$HOME/tmux-sessionizer" << 'EOF'
#!/usr/bin/env bash

if [[ $# -eq 1 ]]; then
    selected=$1
else
    selected=$(find ~/coding ~/ -mindepth 1 -maxdepth 1 -type d | fzf)
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

    chmod +x "$HOME/tmux-sessionizer"
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
                log_warning "Please log out and log back in for the shell change to take effect"
            else
                log_error "zsh not found in /etc/shells"
                return 1
            fi
        else
            log_error "zsh not found"
            return 1
        fi
    fi
}

# Main installation function
main() {
    log_info "Starting SSH machine setup..."
    
#    check_root
    detect_package_manager
    update_system
    install_dependencies
    
    # Install and setup zsh
    install_zsh
    install_oh_my_zsh
    install_zsh_plugins
    setup_zsh_config
    install_fzf
    
    # Install and setup vim
    install_vim
    install_vim_plug
    setup_vim_config
    install_vim_plugins
    
    # Install and setup tmux
    install_tmux
    install_tpm
    setup_tmux_config
    install_tmux_plugins
    create_tmux_sessionizer
    
    # Change default shell
    change_shell_to_zsh
    
    log_success "SSH machine setup completed!"
    log_info "Please restart your terminal or run 'source ~/.zshrc' to apply changes"
    log_info "To use tmux sessionizer, press Ctrl+f in your terminal"
}

# Handle script interruption
trap 'log_error "Script interrupted"; exit 1' INT TERM

# Run main function
main "$@"
