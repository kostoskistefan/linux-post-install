" Plugins
call plug#begin()
    Plug 'itchyny/lightline.vim'
    Plug 'neoclide/coc.nvim', { 'branch': 'release' }
    Plug 'frazrepo/vim-rainbow'
    Plug 'jiangmiao/auto-pairs'
    Plug 'sheerun/vim-polyglot'
call plug#end()

" Plugin Settings
inoremap <expr> <Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"

inoremap <silent><expr> <C-space> coc#refresh()

"GoTo code navigation
nmap <leader>g <C-o>
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gt <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

nmap <leader>rn <Plug>(coc-rename)

"show all diagnostics.
nnoremap <silent> <space>d :<C-u>CocList diagnostics<cr>
"manage extensions.
nnoremap <silent> <space>e :<C-u>CocList extensions<cr>


let g:coc_global_extensions = ['coc-emmet', 'coc-css', 'coc-html', 'coc-json', 'coc-prettier', 'coc-tsserver']


let g:rainbow_active = 1


" Neovim Config
set number
set noshowmode
set clipboard=unnamedplus
filetype plugin indent on
set tabstop=4
set shiftwidth=4
set expandtab
set omnifunc=syntaxcomplete#Complete
syntax on
set undodir=~/.vim/undodir
set undofile
set termguicolors
let g:lightline = {'colorscheme': 'wombat'}
