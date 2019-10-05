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

function! s:Buffer.save() abort
  noautocmd silent write
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

  let lines = map(copy(a:nodes), {_, n -> s:node_to_line(n, 0, {})})
  call setbufline(self._nr, 2, lines)

  let first_line_to_remove = len(a:nodes) + 2
  call deletebufline(self._nr, first_line_to_remove, '$')

  call self.save()
endfunction

function! s:Buffer.append_nodes(lnum, nodes, depth) abort
  let lines = map(copy(a:nodes), {_, n -> s:node_to_line(n, a:depth, {})})
  call append(a:lnum, lines)
endfunction

function! s:Buffer.delete_lines(first, last) abort
  call deletebufline(self._nr, a:first, a:last)
endfunction

function! s:Buffer.current_dir() abort
  let line = getbufline(self._nr, 1)[0]
  return s:decode_dir_metadata(line)
endfunction

function! s:Buffer.node_row(lnum) abort
  let linestr = getbufline(self._nr, a:lnum)[0]
  let row = s:decode_node_line(linestr)
  let row.lnum = a:lnum
  return row
endfunction

function! s:Buffer.update_node_row(node, row, state_changes) abort
  let state = copy(a:row.state)
  for key in keys(a:state_changes)
    let state[key] = a:state_changes[key]
  endfor
  let line = s:node_to_line(a:node, a:row.depth, state)
  call setbufline(self._nr, a:row.lnum, line)
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
  call self.save()
endfunction

function! s:Buffer.redo() abort
  let modified = &modified
  if modified
    redo
    return
  endif

  silent redo

  " TODO: Sometimes 'redo' should change the 'modified' from 'no' to 'yes'.
  " (e.g. edit -> undo [not modified] -> redo [modified])
  call self.save()
endfunction

function! s:node_to_line(node, depth, state) abort
  let meta = s:node_meta_to_line(a:node.id, a:state)
  let indent = s:make_indent(a:depth)
  return meta . indent . a:node.name . (a:node.is_dir ? '/' : '')
endfunction

function! s:node_meta_to_line(node_id, meta) abort
  return 'n' . a:node_id . 's' . get(a:meta, 'tree_open', 0) . ' '
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
  let [metaline, line] = s:split_head_tail(a:whole_line, '\vn\d+s[01]')
  let [indent, name] = s:split_head_tail(line, '\v\s+')
  let is_dir = len(name) > 0 && name[len(name) - 1] == '/'

  let row = {
    \   'name': is_dir ? name[0:-2] : name,
    \   'is_dir': is_dir,
    \   'depth': len(indent) / 2,
    \   'is_new': 1,
    \ }

  if metaline != ''
    let [node_id, state] = s:decode_node_line_meta(metaline)
    let row.is_new = 0
    let row.node_id = node_id
    let row.state = state
  endif

  return row
endfunction

function! s:decode_node_line_meta(meta) abort
  let id_end = matchend(a:meta, '\vn\d+', 0, 1)
  let node_id = str2nr(a:meta[1:id_end-1], 10)
  let state = a:meta[id_end:]
  let tree_open = str2nr(state[1], 10)
  return [node_id, {'tree_open': tree_open}]
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
  if head_end == -1
    return ['', a:str]
  endif

  let head = a:str[0:head_end-1]
  let tail = a:str[head_end:]
  return [head, tail]
endfunction
