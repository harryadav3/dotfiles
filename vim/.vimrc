set scrolloff=8
set number
set relativenumber
set tabstop=4 softtabstop=4
set shiftwidth=4
set expandtab
set smartindent
set guicursor=n-v-c:block,i-ci:ver25,r-cr:hor20,o:hor50
set nowrap
set ignorecase
set smartcase
set hlsearch
set incsearch
set noswapfile

call plug#begin('~/.vim/plugged')

Plug 'tpope/vim-fugitive'
Plug 'vv9k/vim-github-dark'
Plug 'ojroques/vim-oscyank'

call plug#end()

colorscheme ghdark
set background=dark

" OSC 52 clipboard setup
let g:oscyank_silent = v:true
autocmd TextYankPost * if v:event.operator is 'y' | call OSCYankRegister('+') | endif
"
" " Navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" File explorer
nnoremap <leader>pv :Vex<CR>
nnoremap <leader>e :Ex<CR>

" Clipboard - ALL using OSC 52
vnoremap <leader>y :OSCYankVisual<CR>
nnoremap <leader>y :OSCYank<CR>
vnoremap <leader>p "_dP

" File operations
nnoremap <leader>x :!chmod +x %<CR>
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>h :nohlsearch<CR>

" Buffers
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprevious<CR>
nnoremap <leader>bd :bdelete<CR>

 " FZF
nnoremap <C-p> :Files<CR>
nnoremap <leader>fg :GFiles<CR>
nnoremap <leader>fb :Buffers<CR>
nnoremap <leader>fr :Rg<CR>
nnoremap <leader>/ :BLines<CR>

" NERDTree
nnoremap <leader>n :NERDTreeToggle<CR>
nnoremap <leader>nf :NERDTreeFind<CR>
