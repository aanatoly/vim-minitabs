" Vim plugin for autodetecting indentation
" Last Change:  2016 May 4
" Maintainer:   Anatoly Asviyan <aanatoly@gmail.com>
" Licence:      GPLv2

if exists("g:loaded_minitabs") || &cp
  finish
endif
let g:loaded_minitabs= 100
let s:keepcpo = &cpo
set cpo&vim


function! s:adjust_tabs() abort
  let lines = getline(1, 1024)
  let heuristics = {'spaces': 0, 'hard': 0, 'soft': 0}
  let ccomment = 0
  let podcomment = 0
  let triplequote = 0
  let backtick = 0
  let minindent = 8

  let g:xx_adj = 'none'
  for line in lines

    if line =~# '^\s*$'
      continue
    endif

    if line =~# '^\s* \t'
      " mixed indent - stay with defaults
      let g:xx_adj = 'mixed'
      return
    endif

    if line =~# '^\s*/\*'
      let ccomment = 1
    endif
    if ccomment
      if line =~# '\*/'
        let ccomment = 0
      endif
      continue
    endif

    if line =~# '^=\w'
      let podcomment = 1
    endif
    if podcomment
      if line =~# '^=\%(end\|cut\)\>'
        let podcomment = 0
      endif
      continue
    endif

    if triplequote
      if line =~# '^[^"]*"""[^"]*$'
        let triplequote = 0
      endif
      continue
    elseif line =~# '^[^"]*"""[^"]*$'
      let triplequote = 1
    endif

    if backtick
      if line =~# '^[^`]*`[^`]*$'
        let backtick = 0
      endif
      continue
    elseif line =~# '^[^`]*`[^`]*$'
      let backtick = 1
    endif

    if line =~# '^\t'
      let heuristics.hard += 1
    elseif line =~# '^  '
      let heuristics.spaces += 1
      let indent = len(matchstr(line, '^ *'))
      if indent < minindent && indent > 1
        let minindent = indent
      endif
    endif

  endfor

  if heuristics.spaces > heuristics.hard
    let g:xx_adj = 'spaces'
    setlocal expandtab
    let &l:shiftwidth = minindent
    let &l:tabstop = minindent
    set list
  else
    let g:xx_adj = 'tabs'
    setlocal noexpandtab
  endif

endfunction


function! s:detect() abort
  if &modifiable == 0
    return
  endif
    call s:adjust_tabs()
endfunction


augroup minitabs
  autocmd!
  autocmd FileType * call s:detect()
augroup END


