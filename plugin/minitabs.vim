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
" simplify script
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
" simplify script
""""""""""""""""""""""""""""""""""""""""

let s:styles = {
\  "python": {
\   "olcs": ['#'],
\   "mlss": [['"""', '"""'], ["'''", "'''"]],
\  },
\  "sh": {
\   "olcs": ['#'],
\   "mlss": [['<<EOF$', '^EOF$']],
\  },
\  "script": {
\   "olcs": ['#'],
\   "mlss": [],
\  },
\  "c": {
\   "olcs": ['\/\/'],
\   "mlss": [['\/\*', '\*\/']]
\  },
\  "tabs:4": {
\     "ind": ['tabs', 4],
\  },
\  "spaces:2": {
\     "ind": ['spaces', 2],
\  },
\  "default": {
\     "ind": ['spaces', 4],
\  },
\}


let s:mapping = {
\   "python":   "python",
\   "sh":       "sh",
\   "ruby":     "script",
\   "perl":     "script",
\   "c":        "c",
\   "cpp":      "c",
\   "java":     "c",
\   "make":     "tabs:4",
\   "markdown": "spaces:2",
\   "text":     "spaces:2",
\   "vim":      "spaces:2",
\}


function! s:GuessIndent()
  if &modifiable == 0
    return
  endif

  let l:save_cursor = getpos(".")

  let style_name = get(s:mapping, &filetype, "default")
  " no default value here - if smth went wrong we should
  " show the error
  let style = get(s:styles, style_name)
  if has_key(style, 'ind')
    let ind = style['ind']
  elseif has_key(style, 'olcs')
    execute "normal! gg/^\\(\\(\s*[#\\n]\\)\@!.\\)*$"
    let l:lno = line(".")
    let lines = s:SimplifyText(l:lno, l:lno + 128, style['olcs'], style['mlss'])
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

  " echo "ft " . &filetype . ", " . style_name . ", " . g:minitabs_adj

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
  else
    "BUG: should not be here
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

