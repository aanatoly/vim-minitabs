# vim-minitabs
Detects file's indentation style or uses smart defaults.


Main features:
 * uses vim syntax engine to ignore comment and string lines
 * tabs vs spaces is decided from first indented code line
 * always indents makefile with tabs
 * works out of the box for c, c++, java, python, shell, make and may be more

#### Installation
For `Plug` plugin manager, add this line to `.vimrc` after `plug#begin()`
```vim
Plug 'aanatoly/vim-minitabs'
```

#### Set the default
```vim
" indent with spaces
let g:minitabs_fill = 'space'
let g:minitabs_indent = 4
" indent with tabs
let g:minitabs_fill = 'tab'
let g:minitabs_indent = 4
```

#### Change indentation at run time
```vim
:call IndentSet('space', 3)
```

#### Integration with vim-airline
```vim
let g:airline_section_y = '%{IndentPrint()}'
```

