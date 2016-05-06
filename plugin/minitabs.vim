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

let s:minindent = 8
let g:minitabs_adj = 'none'

function! s:CalcIndType(lines) abort
  let heuristics = {'spaces': 0, 'hard': 0, 'soft': 0}
  let backtick = 0

  for line in a:lines

    if line =~# '^\s*$'
      continue
    endif

    if line =~# '^\s* \t'
      " mixed indent - stay with defaults
      return 'mixed'
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
      if indent < s:minindent && indent > 1
        let s:minindent = indent
      endif
    endif

  endfor

  if heuristics.spaces > heuristics.hard
    return 'spaces'
  else
    return 'tabs'
  endif

endfunction


""""""""""""""""""""""""""""""""""""""""
" simplify scripts
""""""""""""""""""""""""""""""""""""""""

" s:find_mls_delim - find left-most triple quote delimeter
function! s:find_mls_delim(line)
  let l:sq_mls_delim = "'''"    " single quote mls delimeter
  let l:sq_pos = match(a:line, l:sq_mls_delim)
  let l:dq_mls_delim = '"""'    " double quote mls delimeter
  let l:dq_pos = match(a:line, l:dq_mls_delim)

  if l:sq_pos == -1 && l:dq_pos == -1
    return ''
  elseif l:sq_pos != -1 && l:dq_pos != -1
    return l:dq_pos < l:sq_pos ? l:dq_mls_delim : l:sq_mls_delim
  elseif l:dq_pos != -1
    return l:dq_mls_delim
  else
    return l:sq_mls_delim
  endif
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
" simplify other formats
""""""""""""""""""""""""""""""""""""""""

function! s:SimplifyText(line1,line2)
  let lines = getline(a:line1,a:line2)
  let i = 0

  " com_start = '#'
  " com_end = '\r'
  while i < len(lines)
    let line = lines[i]
    if line =~# '^\s*$'
      unlet lines[i]
      continue
    endif

    if line =~# '^\s*#'
      unlet lines[i]
      continue
    endif

    if line =~# '^\s*\/\/'
      unlet lines[i]
      continue
    endif

    if line =~# '\\$'
      let lines[i] = lines[i] .'  ' . get(lines, i + 1)
      unlet lines[i + 1]
      continue
    endif

    let i = i + 1
  endwhile

  call append('$', lines)
endfunction


""""""""""""""""""""""""""""""""""""""""
" main
""""""""""""""""""""""""""""""""""""""""
" if !exists('g:minitabs_ft_exclude")
"   let g:minitabs_ft_exclude = ['make']
"
function! s:FixTabs()
  if &modifiable == 0
    return
  endif

  let l:save_cursor = getpos(".")

  if index(['make'], &filetype) > -1
    let type = 'tabs'
  elseif index(['markdown', 'text', 'vim'], &filetype) > -1
    let type = 'text'
  elseif index(['python'], &filetype) > -1
    execute "normal! gg/^\\(\\(\s*[#\\n]\\)\@!.\\)*$"
    let l:lno = line(".")
    let lines = s:SimplifyScript(l:lno, l:lno + 128)
    let type = s:CalcIndType(lines)
  else
    let type = 'none'
  endif

  let g:minitabs_adj = type
  if type == 'tabs'
    setlocal noexpandtab
  elseif type == 'spaces'
    setlocal expandtab
    let &l:shiftwidth = s:minindent
    let &l:tabstop = s:minindent
    set list
  elseif type == 'text'
    setlocal expandtab
    let &l:shiftwidth = 2
    let &l:tabstop = 2
    set list
  endif

  call setpos('.', l:save_cursor)

endfunction
command! FixTabs call <SID>FixTabs()


function! s:GetTabStatus()
  return "ts " . &l:ts . ", sw " . &l:sw . ", et " . &l:et . ", sts " . &l:sts
endfunction


function! s:ShowTabs()
  echo s:GetTabStatus()
endfunction
command! ShowTabs call <SID>ShowTabs()



augroup minitabs
  autocmd!
  autocmd FileType * call s:FixTabs()
augroup END

