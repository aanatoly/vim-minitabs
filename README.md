# vim-minitabs
Automatic indentation detection for vim (beta)

Main features:
 * detect tabs vs spaces
 * ignore indent within text multi-line structures
   * comments `/* ... */`
   * strings `""" ... """`
 * indent detection is wriiten in python, so more people can undertstand it
 * keeps your default settings if it can't guess an indent. This happens with
	empty files, unsupported file types or some strange tabs-spaces mix
 * supports: c, c++, java, python, shell

## Installation
For `Plug` plugin manager, add this line after `plug#begin()`
```vim
Plug 'aanatoly/vim-minitabs'
```

## Integration with vim-airline

```vim
let g:airline_section_y = '%{PrintIndent()}'
```

