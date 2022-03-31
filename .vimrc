set tabstop=2 shiftwidth=2 expandtab autoindent smarttab
set number
set ruler
set visualbell
set cursorline
hi cursorline cterm=none term=none
highlight CursorLine guibg=#303000 ctermbg=234

" Auto detect filetype
autocmd BufRead,BufNewFile *.md,*.markdown set filetype=markdown
autocmd BufRead,BufNewFile *.lytex set filetype=tex
autocmd BufRead,BufNewFile ~/dotfiles/ssh/config set filetype=sshconfig
autocmd BufRead,BufNewFile *.git/config,.gitconfig,.gitmodules,gitconfig set ft=gitconfig
autocmd BufNewFile,BufRead *.html set filetype=htmldjango
autocmd BufNewFile,BufRead .eslintrc set filetype=javascript
autocmd BufNewFile,BufRead *.es6 set filetype=javascript
autocmd BufRead,BufNewFile *.py setlocal foldmethod=indent

call plug#begin('~/.vim/plugged')

Plug '/usr/local/opt/fzf'
Plug 'junegunn/fzf.vim'

Plug 'airblade/vim-gitgutter'
Plug 'tpope/vim-fugitive'

call plug#end()
