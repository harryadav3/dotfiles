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
"set nowrap                      " Don't wrap lines (MAIN FIX!)
set wrap
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

" FAST STARTUP TIPS:
" 1. Run :PlugInstall after first setup
" 2. Use :PlugUpdate occasionally to update plugins
" 3. If still slow, try :PlugClean to remove unused plugins
" 4. Profile startup with: vim --startuptime startup.log file.txt
