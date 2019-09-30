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

function! s:Buffer.cursor_line() abort
  return line('.')
endfunction

function! s:Buffer.put_cursor(lnum, col) abort
  call cursor(a:lnum, a:col)
endfunction

function! s:Buffer.reset_cursor() abort
  call cursor(2, 1)
endfunction

function! s:Buffer.node_lnum(node_id) abort
  let l = 1 " Skip the first line which contains buffer metadata.
  while l < line('$')
    let l += 1
    let row = self.node_row(l)
    if row.node_id == a:node_id
      return l
    endif
  endwhile
  return 0
endfunction

function! s:Buffer.display_nodes(dir_node, nodes) abort
  call setbufline(self._nr, 1, s:buf_metadata(a:dir_node))

  let names = map(copy(a:nodes), {_, n -> s:node_to_line(n, 0)})
  call setbufline(self._nr, 2, names)

  let first_line_to_remove = len(a:nodes) + 2
  call deletebufline(self._nr, first_line_to_remove, '$')

  noautocmd silent write
endfunction

function! s:Buffer.current_dir_node_id() abort
  let line = getbufline(self._nr, 1)[0]
  return s:decode_buf_metadata(line).dir_node_id
endfunction

function! s:Buffer.node_row(lnum) abort
  let linestr = getbufline(self._nr, a:lnum)[0]
  return s:decode_node_line(linestr)
endfunction

function! s:node_to_line(node, depth) abort
  let meta = 'n' . a:node.id . ' '
  let indent = s:make_indent(a:depth * 2)
  return meta . indent . a:node.display_name()
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

function! s:buf_metadata(dir_node) abort
  return 'n' . a:dir_node.id . ' '
endfunction

function! s:decode_buf_metadata(line) abort
  let metaend = matchend(a:line, '\vn\d+', 0, 1)
  let meta = a:line[0:metaend-1]
  return {
    \   'dir_node_id': str2nr(meta[1:], 10),
    \ }
endfunction
