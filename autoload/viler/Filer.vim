let s:Filer = {}

function! viler#Filer#new(commit_id, buf, node_accessor, dirty_checker) abort
  let filer = deepcopy(s:Filer)
  let filer._buf = a:buf
  let filer._nodes = a:node_accessor
  let filer._diff_checker = a:dirty_checker
  let filer._commit_id = a:commit_id
  let filer._commit_state = {'undo_seq_last': 0}
  return filer
endfunction

function! s:Filer.on_buf_enter() abort
  call self._buf.on_enter()
endfunction

function! s:Filer.on_buf_leave() abort
  call self._buf.on_leave()
endfunction

function! s:Filer.commit(commit_id) abort
  let self._commit_id = a:commit_id

  let undotree = self._buf.undotree()
  let self._commit_state = { 'undo_seq_last': undotree.seq_last + 1 }

  call self.refresh()
endfunction

function! s:Filer.buf_state() abort
  let cur_dir = self._buf.current_dir()
  return { 'commit_id': cur_dir.commit_id }
endfunction

function! s:Filer.buffer() abort
  return self._buf
endfunction

function! s:Filer._get_node(node_id, commit_id) abort
  call self._assert_valid_commit_id(a:commit_id)
  return self._nodes.get(a:node_id)
endfunction

function! s:Filer._get_or_make_node(node_id, commit_id, path) abort
  call self._assert_valid_commit_id(a:commit_id)
  return self._nodes.get_or_make(a:node_id, a:path)
endfunction

function! s:Filer._assert_valid_commit_id(commit_id) abort
  if a:commit_id != self._commit_id
    throw '[viler] The row is outdated. You cannot copy/paste rows over saving'
  endif
endfunction

function! s:Filer.display(dir, opts) abort
  call self._nodes.clear()

  let dir_node = self._nodes.make(a:dir)
  let rows = self._list_children(a:dir, 0, get(a:opts, 'states', {}))
  call self._buf.display_rows(self._commit_id, dir_node, rows)

  if !has_key(a:opts, 'states') && bufnr('%') == self._buf.nr()
    call self._buf.reset_cursor()
  endif

  return {'dir': dir_node, 'rows': rows}
endfunction

function! s:Filer.refresh() abort
  if self._buf.modified()
    throw '[viler] Cannot refresh modified buffer'
  endif

  let cur_dir = self._buf.current_dir()

  let states = {}
  let lnum = self._buf.lnum_first() - 1
  let last_lnum = self._buf.lnum_last()
  while lnum < last_lnum
    let lnum += 1
    let row = self._buf.node_row(lnum)

    " When refreshing after saving, added rows have not corresponding node.
    if has_key(row, 'node_id')
      let node = self._nodes.get(row.node_id)
      let states[node.abs_path()] = row.state
    endif
  endwhile

  call self.display(cur_dir.path, {'states': states})
endfunction

function! s:Filer._list_children(dir, depth, states) abort
  let rows = []
  for name in readdir(a:dir)
    let row = {'props': {'depth': a:depth, 'commit_id': self._commit_id}}
    call add(rows, row)
    let row.node = self._nodes.make(viler#Path#join(a:dir, name))
    let node_path = row.node.abs_path()
    let row.state = get(a:states, node_path, {})
    if row.node.is_dir && get(row.state, 'tree_open', 0)
      let row.children = self._list_children(node_path, a:depth + 1, a:states)
    endif
  endfor

  return sort(rows, function('s:sort_rows_by_type_and_name'))
endfunction

function! s:sort_rows_by_type_and_name(row1, row2) abort
  let n1 = a:row1.node
  let n2 = a:row2.node
  if n1.is_dir != n2.is_dir
    return n2.is_dir - n1.is_dir
  endif
  if n1.name == n2.name
    return 0
  endif
  return n1.name < n2.name ? -1 : 1
endfunction

function! s:Filer.open_cursor_file(cmd) abort
  let row = self._buf.node_row(self._buf.lnum_cursor())
  if row.is_new
    throw '[viler] This file is not saved yet'
  endif

  let node = self._get_node(row.node_id, row.commit_id)
  if node.is_dir
    call self.display(node.abs_path(), {})
  else
    execute a:cmd node.abs_path()
  endif
endfunction

function! s:Filer.go_up_dir() abort
  let cur_dir = self._buf.current_dir()
  let dir_node = self._get_node(cur_dir.node_id, cur_dir.commit_id)

  let dir = {'path': dir_node.abs_path(), 'depth': 0}
  if self._is_dirty(dir)
    throw '[viler] Cannot leave unsaved edited directory'
  endif

  let result = self.display(dir_node.dir, {})

  let prev_dir_node_id = 0
  for row in result.rows
    if row.node.name == dir_node.name
      let prev_dir_node_id = row.node.id
      break
    endif
  endfor

  if 0 < prev_dir_node_id
    let lnum = self._buf.node_lnum(prev_dir_node_id)
    if 0 < lnum
      call self._buf.put_cursor(lnum, 1)
    endif
  endif
endfunction

function! s:Filer._is_dirty(dir) abort
  return self._diff_checker.is_dirty(a:dir, self._buf, self._commit_id)
endfunction

function! s:Filer.toggle_tree() abort
  call self.toggle_tree_at(self._buf.lnum_cursor())
endfunction

function! s:Filer.toggle_tree_at(lnum) abort
  if a:lnum < self._buf.lnum_first() || self._buf.lnum_last() < a:lnum
    return
  endif

  let row = self._buf.node_row(a:lnum)
  if !row.is_dir
    return
  endif

  let modified = self._buf.modified()

  let node = self._get_node(row.node_id, row.commit_id)
  if row.state.tree_open
    let dir = {'lnum': row.lnum + 1, 'path': node.abs_path(), 'depth': row.depth + 1}
    if self._is_dirty(dir)
      throw '[viler] Cannot close unsaved edited directory'
    endif
    call self._buf.update_node_row(node, row, {'tree_open': 0})
    call self._close_tree(node, row)
  else

    call self._buf.update_node_row(node, row, {'tree_open': 1})
    let rows = self._list_children(node.abs_path(), 0, {})
    let nodes = map(rows, 'v:val.node')
    call self._buf.append_nodes(row.lnum, nodes, {
      \   'commit_id': self._commit_id,
      \   'depth': row.depth + 1,
      \ })
  endif

  if !modified
    call self._buf.save()
  endif
endfunction

function! s:Filer._close_tree(dir_node, dir_row) abort
  let last_lnum = self._buf.lnum_last()
  let l = a:dir_row.lnum

  while 1
    let l += 1
    if l > last_lnum
      break
    endif

    let row = self._buf.node_row(l)
    if row.depth <= a:dir_row.depth
      break
    endif
    call self._nodes.remove(row.node_id)
  endwhile
  if a:dir_row.lnum + 1 < l
    call self._buf.delete_lines(a:dir_row.lnum + 1, l - 1)
  endif
endfunction

function! s:Filer.undo() abort
  if self._buf.modified()
    call self._buf.undo()
    return
  endif

  let prev_dir = self._buf.current_dir()
  call self._buf.undo()

  " Currently we do not support undo over commit.
  let curhead = self._buf.undotree_curhead()
  if curhead.seq <= self._commit_state.undo_seq_last
    return
  endif

  call self._nodes.clear()
  call self._restore_nodes_on_buf(prev_dir)

  call self._buf.save()
endfunction

function! s:Filer.redo() abort
  if self._buf.modified()
    call self._buf.redo()
    return
  endif

  let prev_dir = self._buf.current_dir()
  let modified = self._buf.redo()

  call self._nodes.clear()
  call self._restore_nodes_on_buf(prev_dir)

  if !modified
    call self._buf.save()
  endif
endfunction

function! s:Filer._restore_nodes_on_buf(prev_dir) abort
  let cur_dir = self._buf.current_dir()
  call self._get_or_make_node(cur_dir.node_id, cur_dir.commit_id, cur_dir.path)

  let prev_dir_lnum = 0
  let prev_depth = 0
  let prev_name = ''
  let dir_path = cur_dir.path
  let l = self._buf.lnum_first() - 1
  let last_l = self._buf.lnum_last()
  while l < last_l
    let l += 1
    let row = self._buf.node_row(l)

    if row.is_new
      continue
    endif

    if prev_depth < row.depth
      let dir_path .= '/' . prev_name
    elseif prev_depth > row.depth
      let idt = row.depth
      while idt < prev_depth
        let dir_path = fnamemodify(dir_path, ':h')
        let idt += 1
      endwhile
    endif

    let file_path = viler#Path#join(dir_path, row.name)
    call self._get_or_make_node(row.node_id, row.commit_id, file_path)
    let prev_depth = row.depth
    let prev_name = row.name

    if file_path == a:prev_dir.path
      let prev_dir_lnum = l
    endif
  endwhile

  if 0 < prev_dir_lnum
    call self._buf.put_cursor(prev_dir_lnum, 1)
  endif
endfunction
