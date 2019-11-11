let s:Buffer = {}

function! viler#Buffer#new() abort
  let buffer = deepcopy(s:Buffer)
  let buffer._nr = 0

  " This stores the last lnum of the buffer during
  " the buffer is not active (not a 'current buffer').
  " I could not find a way to get the last lnum of non-current buffer.
  let buffer._lnum_last = 0

  return buffer
endfunction

function! s:Buffer.on_enter() abort
  let self._lnum_last = 0
endfunction

function! s:Buffer.on_leave() abort
  let self._lnum_last = line('$')
endfunction

function! s:Buffer.bind(bufnr) abort
  let self._nr = a:bufnr
endfunction

function! s:Buffer.nr() abort
  return self._nr
endfunction

function! s:Buffer.lnum_first() abort
  return 2
endfunction

function! s:Buffer.lnum_last() abort
  if self._lnum_last > 0
    return self._lnum_last
  endif
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
  while l < self.lnum_last()
    let l += 1
    let row = self.node_row(l)
    if row.node_id == a:node_id
      return l
    endif
  endwhile
  return 0
endfunction

function! s:Buffer.display_nodes(commit_id, dir_node, nodes) abort
  call setbufline(self._nr, 1, s:filer_metadata(a:commit_id, a:dir_node))

  let lines = map(copy(a:nodes), {_, n -> self._node_to_line(n, 0, {})})
  call setbufline(self._nr, 2, lines)

  let first_line_to_remove = len(a:nodes) + 2
  call deletebufline(self._nr, first_line_to_remove, '$')

  " If this buffer is hidden, `_lnum_last` could be outdated.
  " For example, another filer may delete a file in a directory
  " this buffer displays. In this case the last lnum must decrease.
  if self._lnum_last > 0
    let self._lnum_last = line('$')
  endif

  call self.save()
endfunction

function! s:Buffer.append_nodes(lnum, nodes, depth) abort
  let lines = map(copy(a:nodes), {_, n -> self._node_to_line(n, a:depth, {})})
  call append(a:lnum, lines)
endfunction

function! s:Buffer.delete_lines(first, last) abort
  call deletebufline(self._nr, a:first, a:last)
endfunction

function! s:Buffer.current_dir() abort
  let line = getbufline(self._nr, 1)[0]
  return s:decode_filer_metadata(line)
endfunction

function! s:Buffer.node_row(lnum) abort
  let linestr = getbufline(self._nr, a:lnum)[0]
  let row = viler#Buffer#decode_node_line(linestr)
  let row.lnum = a:lnum
  return row
endfunction

function! s:Buffer.update_node_row(node, row, state_changes) abort
  let state = copy(a:row.state)
  for key in keys(a:state_changes)
    let state[key] = a:state_changes[key]
  endfor
  let line = self._node_to_line(a:node, a:row.depth, state)
  call setbufline(self._nr, a:row.lnum, line)
endfunction

function! s:Buffer.modified() abort
  return getbufvar(self._nr, '&modified')
endfunction

function! s:Buffer.undotree() abort
  return undotree()
endfunction

function! s:Buffer.undotree_curhead() abort
  for entry in self.undotree().entries
    if has_key(entry, 'curhead')
      return entry
    endif
  endfor
  return 0
endfunction

function! s:Buffer.undo() abort
  silent undo
endfunction

function! s:Buffer.redo() abort
  " Decide whether the 'redo'ne buffer should be modified or not.
  " For example, We don't want to make a buffer 'modified' just by 'redo'ing tree toggling.
  let curhead = self.undotree_curhead()
  let modified = !has_key(curhead, 'save')
  silent redo
  return modified
endfunction

function! s:Buffer._node_to_line(node, depth, state) abort
  let indent = s:make_indent(a:depth)

  let tree_open = a:node.is_dir ? get(a:state, 'tree_open', 0) : 2
  let meta = join([self._nr, a:node.id, tree_open], '_')

  return indent . a:node.name . (a:node.is_dir ? '/' : '') . ' |' . meta
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

function! viler#Buffer#decode_node_line(whole_line) abort
  let [indent, line] = viler#lib#Str#split_head_tail(a:whole_line, '\v^\s*')

  let idx_sep = viler#lib#Str#last_index(line, ' ')

  if idx_sep >= 0 && line[idx_sep + 1] == '|'
    let name = trim(line[0:idx_sep - 1])
    let metaline = line[idx_sep + 1:]
  else
    let name = trim(line)
    let metaline = ''
  endif

  let is_dir = len(name) > 0 && name[len(name) - 1] == '/'

  let row = {
    \   'name': is_dir ? name[0:-2] : name,
    \   'is_dir': is_dir,
    \   'depth': len(indent) / 2,
    \   'is_new': 1,
    \ }

  if metaline != ''
    let [bufnr, node_id, state] = s:decode_node_line_meta(metaline)
    let row.is_new = 0
    let row.bufnr = bufnr
    let row.node_id = node_id
    let row.state = state
  endif

  return row
endfunction

function! s:decode_node_line_meta(meta) abort
  let [bufnr, node_id, state] = split(a:meta[1:], '_')
  let state = {'tree_open': str2nr(state[0])}
  return [str2nr(bufnr), str2nr(node_id), state]
endfunction

function! s:filer_metadata(commit_id, dir_node) abort
  let meta = ' ||' . a:commit_id . '_' . a:dir_node.id
  return a:dir_node.abs_path() . meta
endfunction

function! s:decode_filer_metadata(line) abort
  let idx_sep = viler#lib#Str#last_index(a:line, ' ')
  let meta = a:line[idx_sep + 1:]
  let dir_path = a:line[0:idx_sep - 1]
  let [commit_id, node_id] = split(meta[2:], '_')
  return {
    \   'commit_id': str2nr(commit_id),
    \   'node_id': str2nr(node_id),
    \   'path': trim(dir_path),
    \ }
endfunction
