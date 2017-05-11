" Vim plugin for autodetecting indentation
" Last Change:  2016 May 4
" Maintainer:   Anatoly Asviyan <aanatoly@gmail.com>
" Licence:      GPLv2

function! PrintIndent()
  return "sw:" . &l:sw . " et:" . &l:et
endfunction


if exists("g:loaded_minitabs") || &cp || &modifiable == 0
  finish
endif
let g:loaded_minitabs = 100


let g:get_indent = fnamemodify(resolve(expand('<sfile>:p')), ':h') ."/get_indent"

function! s:SetIndent()
  let src = join(getline(1, 100), "\n")
  let conf = system(g:get_indent . " --ft " . &filetype, src)
  execute conf
endfunction

augroup minitabs
  autocmd!
  autocmd FileType * call s:SetIndent()
augroup END

