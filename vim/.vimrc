set scrolloff=8
set number 
set relativenumber
set tabstop=4  softtabstop=4
set shiftwidth=4
set expandtab
set smartindent

call plug#begin('~/.vim/plugged')
Plug 'junegun/fzf', {'do':{ -> fzf#install() } }
Plug 'junegunn/fzf.vim' 
call plug#end()

"Our Remaps"
let mapleader = " "
nnoremap <leader>pv :Vex<CR>
nnoremap <leader>e :Ex<CR>
vnoremap <leader>p "_dP
vnoremap <leader>y "+y

nnoremap <leader>x :!chmod +x %<CR>



