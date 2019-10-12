setlocal indentexpr=viler#get_indent()
setlocal indentkeys=o,O
setlocal shiftwidth=2

function! viler#get_indent() abort
  if v:lnum == 1
    return 0
  endif

  let above = getline(v:lnum - 1)
  let row = viler#Buffer#decode_node_line(above)
  if row.is_dir && row.state.tree_open
    return indent(v:lnum - 1) + shiftwidth()
  endif
  return indent(v:lnum - 1)
endfunction
