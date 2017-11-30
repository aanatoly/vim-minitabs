" Vim plugin for autodetecting indentation
" Last Change:  2016 May 4
" Maintainer:   Anatoly Asviyan <aanatoly@gmail.com>
" Licence:      GPLv2

function! IndentPrint()
	return &l:sw . ":" . (&l:et ? "space" : "tab")
endfunction

if exists("g:loaded_minitabs") || &cp || &modifiable == 0
  finish
endif
let g:loaded_minitabs = 1

if has("python3")
	let s:pyfile = "py3file "
	let s:py = "py3 "
elseif has("python")
	let s:pyfile = "pyfile "
	let s:py = "py "
else
	echohl Error
	echo "Error: minitabs requires vim compiled with +python or +python3"
	echohl None
	finish
endif

if !exists("g:minitabs_fill")
  let g:minitabs_fill = 'space'
endif
if !exists("g:minitabs_indent")
  let g:minitabs_indent = 4
endif

let s:main_py = resolve(expand('<sfile>:p:h')) ."/main.py"
execute s:pyfile . s:main_py

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

function! s:IndentGuess()
  exec s:py 'indent_guess()'
endfunction

augroup minitabs
  autocmd!
  autocmd FileType * call s:IndentGuess()
  autocmd BufNewFile * call s:IndentGuess()
augroup END
