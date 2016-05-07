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

""""""""""""""""""""""""""""""""""""""""
" main
""""""""""""""""""""""""""""""""""""""""

let g:minitabs_adj = 'none'

function! s:CalcIndType(lines) abort
  let heuristics = {'spaces': 0, 'hard': 0 }
  let backtick = 0
  let l:minindent = 8

  for line in a:lines

    if line =~# '^\s*$'
      continue
    endif

    if line =~# '^\s* \t'
      " mixed indent - stay with defaults
      return ['mixed', 0]
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
      if indent < l:minindent && indent > 1
        let l:minindent = indent
      endif
    endif

  endfor

  if heuristics.spaces > heuristics.hard
    return ['spaces' , l:minindent]
  else
    return ['tabs', 4]
  endif

endfunction


" s:FindDelim - find left-most triple quote delimeter
function! s:FindDelim(line, mlss)
  let l:stack = []

  for i in len(a:mlss)
    let l:pos = match(a:line, a:mlss[i][0])
    if l:pos == -1
      continue
    endif
    l:stack += [l:pos, a:mlss[i]]
  endfor
  call sort(l:stack)

  if l:stack == []
    return []
  endif

  return l:stack[1]
endfunction


" s:SimplifyText- simplify script-like buffers
" Rules are:
"  * drop one line comments
"  * drop empty lines
"  * squash multiline statements into single line
"    |  some long line \
"    |     in bash with a \    ==> some long line in bash with a lot of args
"    |     lot of args
"  * squash multi-line strings into single line
"    |  a = ''' ffff
"    |     ggggg                ==> a = '''ffff ggggg eeeee'''' ==> a = 'dupa'
"    |    eeeee"
function! s:SimplifyText(line1,line2, olcs, mlss)
  let lines = getline(a:line1,a:line2)
  let i = 0
  let l:mls = 0   "multi line string, ''' ...''' or """ ... """
  let l:sq_mls_delim = "'''"    " single quote mls delimeter
  let l:dq_mls_delim = '"""'    " double quote mls delimeter
  let l:cur_mls_delim = ''      " current mls delimeter

  while i < len(lines)
    let lines[i] = lines[i]

    " drop empty lines
    if lines[i] =~# '^\s*$'
      unlet lines[i]
      continue
    endif

    " drop one line comments
    for olc in a:olcs
      if lines[i] =~# '^\s*' . olc .'.*$'
        unlet lines[i]
        continue
      endif
    endfor

    " squash multi line statements
    if lines[i] =~# '\\$'
      if i + 1 < len(lines)
        " let lines[i] = lines[i] .'  ' . get(lines, i + 1)
        let lines[i] = lines[i] .'  ' . substitute(lines[i + 1], '^\s*', '', '')
        unlet lines[i + 1]
      endif
      continue
    endif

    " squash multi line strings
    let delim = s:find_mls_delim(lines[i], a:mlss)
    if delim != []
      while i < len(lines)
        let nline = substitute(lines[i], delim[0] . '\_.\{-}' . delim[1], '"dupa"', '')
        if nline == lines[i]
          let lines[i] = lines[i] . get(lines, i + 1)
          unlet lines[i + 1]
          continue
        endif

        let lines[i] = nline
        break
      endwhile
      continue
    endif

    let i = i + 1
  endwhile

  return lines
endfunction


""""""""""""""""""""""""""""""""""""""""
" simplify scripts
""""""""""""""""""""""""""""""""""""""""

" s:find_mls_delim - find left-most triple quote delimeter
function! s:find_mls_delim(line, mlss)
  let l:sq_mls_delim = "'''"    " single quote mls delimeter
  let l:sq_pos = match(a:line, l:sq_mls_delim)
  let l:dq_mls_delim = '"""'    " double quote mls delimeter
  let l:dq_pos = match(a:line, l:dq_mls_delim)

  if l:sq_pos == -1 && l:dq_pos == -1
    return []
  endif

  if l:sq_pos != -1 && l:dq_pos != -1
    let l:rc = l:dq_pos < l:sq_pos ? l:dq_mls_delim : l:sq_mls_delim
  elseif l:dq_pos != -1
    let l:rc = l:dq_mls_delim
  else
    let l:rc = l:sq_mls_delim
  endif
  return [l:rc, l:rc]
endfunction


" s:SimplifyScript - simplify script-like buffers
" Rules are:
"  * comment is one-liner starting with '#'
"  * drop comment only line
"  * drop empty lines
"  * squash multiline block into single line
"    |  some long line \
"    |     in bash with a \    ==> some long line in bash with a lot of args
"    |     lot of args
"  * squash multi-line strings into single line
"    |  a = ''' ffff
"    |     ggggg                ==> a = '''ffff ggggg eeeee'''' ==> a = 'dupa'
"    |    eeeee"
function! s:SimplifyScript(line1,line2)
  let lines = getline(a:line1,a:line2)
  let i = 0
  let l:mls = 0   "multi line string, ''' ...''' or """ ... """
  let l:sq_mls_delim = "'''"    " single quote mls delimeter
  let l:dq_mls_delim = '"""'    " double quote mls delimeter
  let l:cur_mls_delim = ''      " current mls delimeter

  while i < len(lines)
    let lines[i] = lines[i]

    if lines[i] =~# '^\s*$'
      unlet lines[i]
      continue
    endif

     if lines[i] =~# '^\s*#.*$'
      unlet lines[i]
      continue
    endif

    if lines[i] =~# '\\$'
      if i + 1 < len(lines)
        " let lines[i] = lines[i] .'  ' . get(lines, i + 1)
        let lines[i] = lines[i] .'  ' . substitute(lines[i + 1], '^\s*', '', '')
        unlet lines[i + 1]
      endif
      continue
    endif

    let delim = s:find_mls_delim(lines[i])
    if delim != ''
      while i < len(lines)
        let nline = substitute(lines[i], delim . '\_.\{-}' . delim, '"dupa"', '')
        if nline == lines[i]
          let lines[i] = lines[i] . get(lines, i + 1)
          unlet lines[i + 1]
          continue
        endif

        let lines[i] = nline
        break
      endwhile
      continue
    endif

    let i = i + 1
  endwhile

  return lines
endfunction


command! -range=% SimplifyScript call <SID>SimplifyScript(<line1>,<line2>)

""""""""""""""""""""""""""""""""""""""""
" main
""""""""""""""""""""""""""""""""""""""""

function! s:GuessIndent()
  if &modifiable == 0
    return
  endif

  let l:save_cursor = getpos(".")

  if index(['make'], &filetype) > -1
    let ind = ['tabs', 4]
  elseif index(['markdown', 'text', 'vim'], &filetype) > -1
    let ind = ['spaces', 2]
  elseif index(['python'], &filetype) > -1
    execute "normal! gg/^\\(\\(\s*[#\\n]\\)\@!.\\)*$"
    let l:lno = line(".")
    let l:olcs = ['#']
    let l:mlss = [['"""', '"""'], ["'''", "'''"]]
    let lines = s:SimplifyText(l:lno, l:lno + 128, l:olcs, l:mlss)
    let ind = s:CalcIndType(lines)
  else
    let ind = ['none', 0]
  endif

  if ind[1] < 2
    let ind[1] = &l:shiftwidth
  endif
  if ind[1] < 2
    let ind[1] = 2
  endif
  let g:minitabs_adj = "" . ind[0] . ":" . ind[1]

  if ind[0] == 'tabs'
    setlocal noexpandtab
    let &l:shiftwidth = ind[1]
    let &l:tabstop = ind[1]
    let &l:softtabstop = ind[1]
  elseif ind[0]  == 'spaces'
    setlocal expandtab
    let &l:shiftwidth = ind[1]
    let &l:tabstop = ind[1]
    let &l:softtabstop = ind[1]
    set list
  endif

  call setpos('.', l:save_cursor)

endfunction
command! GuessIndent call <SID>GuessIndent()


function! GetTabStatus()
  if &l:ts == &l:sw && &l:sw == &l:sts
    return !&l:et ? 'tabs:' . &l:ts : 'spaces:' .&l:ts
  else
    return "ts " . &l:ts . " sw " . &l:sw . " et " . &l:et . " sts " . &l:sts
  endif
endfunction


function! s:ShowTabs()
  echo GetTabStatus()
endfunction
command! ShowTabs call <SID>ShowTabs()


augroup minitabs
  autocmd!
  autocmd FileType * call s:GuessIndent()
augroup END

