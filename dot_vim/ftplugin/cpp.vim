" configure tabwidth and insert spaces instead of tabs
set tabstop=4        " tab width is 4 spaces
set shiftwidth=4     " indent also with 4 spaces
set expandtab        " expand tabs to spaces
" highlight matching braces
set showmatch
" intelligent c++ comments
set comments=sl:/*,mb:\ *,elx:\ */

" search paths for headers (gf command)
"let &path.='/usr/include/AL,../'

" ale settings
let s:flags = '
  \ -std=c++11 -Wall
  \ $(root-config --cflags)
  \ $(bat-config --cflags)
  \ $(geant4-config) --cflags
  \ $(clhep-config) --cflags'

let g:ale_objcpp_clang_options = s:flags
let g:ale_cpp_clang_options    = s:flags
let g:ale_objcpp_gcc_options   = s:flags
let g:ale_cpp_gcc_options      = s:flags

" YCM settings
nnoremap <leader>lp :YcmCompleter GoTo<CR>

source ~/.vim/ftplugin/cern_root.vim
