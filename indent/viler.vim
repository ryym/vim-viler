setlocal indentexpr=viler#get_indent()
setlocal indentkeys=o,O
setlocal shiftwidth=2

function! viler#get_indent() abort
  if v:lnum == 1
    return 0
  endif

  let above = getline(v:lnum - 1)
  return indent(v:lnum - 1) + (above[len(above) - 1] == '/' ? 2 : 0)
endfunction
