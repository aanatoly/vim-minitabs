" Vim plugin for autodetecting indentation
" Last Change:  2016 May 4
" Maintainer:   Anatoly Asviyan <aanatoly@gmail.com>
" Licence:      GPLv2

if !has('python')
  finish
endif

if exists("g:loaded_minitabs") || &cp || &modifiable == 0
  finish
endif
let g:loaded_minitabs = 100

let g:minitabs_fill = 'space'
let b:minitabs_indent = 4

if !exists("g:minitabs_fill")
  let b:minitabs_fill = 'space'
endif
if !exists("g:minitabs_indent")
  let g:minitabs_indent = 4
endif

let s:main_py = resolve(expand('<sfile>:p:h')) ."/main.py"
execute 'pyfile ' . s:main_py

function! IndentSet(fill, ind)
  let b:minitabs_fill = a:fill
  let b:minitabs_indent = a:ind
  if a:fill == "tab"
    setlocal noet nolist
  elseif a:fill == "space"
    setlocal et list
  endif
  let &l:ts=a:ind
  let &l:sts=a:ind
  let &l:sw=a:ind
endfunction

function! IndentPrint()
  return b:minitabs_fill . ":" . b:minitabs_indent
endfunction

function! s:IndentGuess()
  py indent_guess()
endfunction

augroup minitabs
  autocmd!
  autocmd FileType * call s:IndentGuess()
  autocmd BufNewFile * call IndentSet(g:minitabs_fill, g:minitabs_indent)
augroup END

" FIXME: remove
function! PrintIndent()
  return IndentPrint()
endfunction

