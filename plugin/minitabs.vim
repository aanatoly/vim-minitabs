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

let s:main_py = resolve(expand('<sfile>:p:h')) ."/main.py"
execute 'pyfile ' . s:main_py

function! IndentSet(fill, ind)
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
  return "sw:" . &l:sw . " et:" . &l:et
endfunction

function! s:IndentGuess()
  return
  let src = join(getline(1, 100), "\n")
  let conf = system(g:get_indent . " --ft " . &filetype, src)
  execute conf
endfunction

augroup minitabs
  autocmd!
  autocmd FileType * call s:IndentGuess()
augroup END

" FIXME: remove
function! PrintIndent()
  return "sw:" . &l:sw . " et:" . &l:et
endfunction

