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

function! s:Buffer.lnum_first() abort
  return 2
endfunction

function! s:Buffer.lnum_last() abort
  return line('$')
endfunction

function! s:Buffer.lnum_cursor() abort
  return line('.')
endfunction

function! s:Buffer.put_cursor(lnum, col) abort
  call cursor(a:lnum, a:col)
endfunction

function! s:Buffer.reset_cursor() abort
  call cursor(self.lnum_first(), 1)
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
  call setbufline(self._nr, 1, s:dir_metadata(a:dir_node))

  let names = map(copy(a:nodes), {_, n -> s:node_to_line(n, 0)})
  call setbufline(self._nr, 2, names)

  let first_line_to_remove = len(a:nodes) + 2
  call deletebufline(self._nr, first_line_to_remove, '$')

  noautocmd silent write
endfunction

function! s:Buffer.current_dir() abort
  let line = getbufline(self._nr, 1)[0]
  return s:decode_dir_metadata(line)
endfunction

function! s:Buffer.node_row(lnum) abort
  let linestr = getbufline(self._nr, a:lnum)[0]
  return s:decode_node_line(linestr)
endfunction

function! s:Buffer.modified() abort
  return &modified
endfunction

function! s:Buffer.undo() abort
  let modified = &modified
  if modified
    undo
    return
  endif

  silent undo
  noautocmd silent write
endfunction

function! s:Buffer.redo() abort
  let modified = &modified
  if modified
    redo
    return
  endif

  silent redo
  noautocmd silent write
endfunction

function! s:node_to_line(node, depth) abort
  let meta = 'n' . a:node.id . ' '
  let indent = s:make_indent(a:depth * 2)
  return meta . indent . a:node.name . (a:node.is_dir ? '/' : '')
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

function! s:decode_node_line(whole_line) abort
  let [meta, line] = s:split_head_tail(a:whole_line, '\vn\d+')
  let [indent, name] = s:split_head_tail(line, '\v\s+')
  let is_dir = name[len(name) - 1] == '/'
  return {
    \   'node_id': str2nr(meta[1:], 10),
    \   'name': is_dir ? name[0:-2] : name,
    \   'is_dir': is_dir,
    \   'depth': indent / 2,
    \ }
endfunction

function! s:dir_metadata(dir_node) abort
  let meta = 'n' . a:dir_node.id . ' '
  return meta . a:dir_node.abs_path()
endfunction

function! s:decode_dir_metadata(line) abort
  let [meta, dir_path] = s:split_head_tail(a:line, '\vn\d+')
  return {
    \   'node_id': str2nr(meta[1:], 10),
    \   'path': trim(dir_path),
    \ }
endfunction

function! s:split_head_tail(str, head_pat) abort
  let head_end = matchend(a:str, a:head_pat, 0, 1)
  let head = a:str[0:head_end-1]
  let tail = a:str[head_end:]
  return [head, tail]
endfunction
