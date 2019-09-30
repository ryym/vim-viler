let s:Buffer = {'_nr': 0}

function! efiler#Buffer#new() abort
  let buffer = deepcopy(s:Buffer)
  return buffer
endfunction

function! s:Buffer.open(path) abort
  execute 'silent edit' a:path
  let self._nr = bufnr('%')
  return self._nr
endfunction

function! s:Buffer.nr() abort
  return self._nr
endfunction

function! s:Buffer.display_nodes(nodes) abort
  let first_line_to_remove = len(a:nodes) + 1
  let names = map(copy(a:nodes), {_, n -> s:node_to_line(n, 0)})
  call setbufline(self._nr, 1, names)
  call deletebufline(self._nr, first_line_to_remove, '$')

  noautocmd silent write
endfunction

function! s:Buffer.node_row(lnum) abort
  let linestr = getbufline(self._nr, line(a:lnum))[0]
  return s:decode_node_line(linestr)
endfunction

function! s:node_to_line(node, depth) abort
  let meta = 'n' . a:node.id . ' '
  let indent = s:make_indent(a:depth * 2)
  return meta . indent . a:node.name
endfunction

function! s:make_indent(level) abort
  let s = ''
  let i = 0
  while i < a:level
    let s .= '  '
    let i += 1
  endwhile
  return s
endfunction

function! s:decode_node_line(line) abort
  let metaend = matchend(a:line, '\vn\d+', 0, 1)
  let meta = a:line[0:metaend-1]
  let name = trim(a:line[metaend:])
  return {
    \   'node_id': str2nr(meta[1:], 10),
    \   'name': name,
    \ }
endfunction
