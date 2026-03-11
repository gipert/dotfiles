" LaTex settings
filetype indent on
set tabstop=2
set shiftwidth=2
set grepprg=grep\ -nH\ $*
set spell
set spelllang=en_us
set tw=99

" disable builtin syntax checking
let g:tex_no_error = 1

" vimtex settings
let g:vimtex_motion_enabled = 0
" use UltiSnips
let g:vimtex_imaps_enabled = 0

" quickfix window
let g:vimtex_quickfix_open_on_warning = 0
let g:vimtex_quickfix_autoclose_after_keystrokes = 2

" use vim-tex-fold instead of vimtex's
let g:vimtex_fold_enabled = 0
let g:vimtex_fold_manual = 1
let g:tex_fold_additional_envs = ['tikzpicture', 'titlepage']

if has('mac')
  let g:vimtex_view_method = 'skim'
else
  let g:vimtex_view_method = 'zathura'
endif

let g:vimtex_compiler_latexmk = {
\  'options': [
\    '-pdf',
\    '-verbose',
\    '-file-line-error',
\    '-interaction=nonstopmode',
\    '-shell-escape',
\  ],
\}

" Enable YCM
if !exists('g:ycm_semantic_triggers')
    let g:ycm_semantic_triggers = {}
endif
augroup VimEnter
    let g:ycm_semantic_triggers.tex = g:vimtex#re#youcompleteme
augroup END

let g:ycm_min_num_of_chars_for_completion = 99
let g:ycm_seed_identifiers_with_syntax = 0
