let s:Filer = {}

function! viler#Filer#new(commit_id, buf, node_store, dirty_checker) abort
  let filer = deepcopy(s:Filer)
  let filer._buf = a:buf
  let filer._nodes = a:node_store
  let filer._diff_checker = a:dirty_checker
  let filer._commit_id = a:commit_id
  let filer._commit_state = {'undo_seq_last': 0}
  let filer._config = {'show_dotfiles': 0}
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

  let lnum_cursor = self._buf.lnum_cursor()
  let cursor_abs_path = self._abs_path_of_row(lnum_cursor)

  call self.refresh()

  " Adjust the cursor position. For example if you add a new file and save,
  " the files are sorted at refresh() and the added file may move to the different line.
  " In this case the cursor should be moved as well to the line of that file.
  if bufnr('%') is# self._buf.nr() && lnum_cursor >= self._buf.lnum_first()
    let colnum = self._buf.colnum_cursor()
    let l = self._buf.lnum_first()
    while l <= self._buf.lnum_last()
      let row = self._buf.row_info(l)
      let node = self._nodes.get_node(row.node_id)
      if node.abs_path() is# cursor_abs_path
        call self._buf.put_cursor(l, colnum)
        break
      endif
      let l += 1
    endwhile
  endif
endfunction

function! s:Filer.buffer() abort
  return self._buf
endfunction

function! s:Filer._get_node(node_id, commit_id) abort
  call self._assert_valid_commit_id(a:commit_id)
  return self._nodes.get_node(a:node_id)
endfunction

function! s:Filer._get_or_make_node(node_id, commit_id, path) abort
  call self._assert_valid_commit_id(a:commit_id)
  return self._nodes.get_or_make_node(a:node_id, a:path)
endfunction

function! s:Filer._assert_valid_commit_id(commit_id) abort
  if a:commit_id isnot# self._commit_id
    throw '[viler] The row is outdated. You cannot copy/paste rows over saving'
  endif
endfunction

function! s:Filer.display(dir, opts) abort
  call self._nodes.clear_displayed_nodes()
  let dir_node = self._nodes.get_or_make_node_from_path(a:dir)
  let rows = self._list_children(a:dir, 0, a:opts)
  call self._buf.display_rows(self._commit_id, dir_node, rows)
  return {'dir': dir_node, 'rows': rows}
endfunction

function! s:Filer.config() abort
  return self._config
endfunction

function! s:Filer.modify_config(conf) abort
  for key in keys(a:conf)
    let self._config[key] = a:conf[key]
  endfor
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
    let row = self._buf.row_info(lnum)

    " When refreshing after saving, added rows have not corresponding node.
    if has_key(row, 'node_id') && row.bufnr is# self._buf.nr()
      let node = self._nodes.get_node(row.node_id)
      let states[node.abs_path()] = row.state
    endif
  endwhile

  call self.display(cur_dir.path, {'states': states, 'refresh_nodes': 1})
endfunction

function! s:Filer._abs_path_of_row(lnum) abort
  let lfirst = self._buf.lnum_first()
  if a:lnum < lfirst
    return self._buf.current_dir().path
  endif

  let target_row = self._buf.row_info(a:lnum)

  " We do not use node.abs_path() here because the file name
  " under the cursor may be renamed and is not saved yet.

  let paths = [target_row.name]
  let depth = target_row.depth
  let l = a:lnum - 1
  while lfirst <= l && 0 < depth
    let row = self._buf.row_info(l)
    if row.depth < depth
      call add(paths, row.name)
      let depth -= 1
    endif
    let l -= 1
  endwhile

  let paths = reverse(paths)
  let rel_path = paths[0]
  for name in paths[1:-1]
    let rel_path = viler#Path#join(rel_path, name)
  endfor

  return viler#Path#join(self._buf.current_dir().path, rel_path)
endfunction

function! s:Filer._list_children(dir, depth, opts) abort
  let show_dotfiles = self._config.show_dotfiles
  let rows = []
  for name in viler#lib#Fs#readdir(a:dir)
    if !show_dotfiles && name[0] is# '.'
      continue
    endif
    let row = {'props': {'depth': a:depth, 'commit_id': self._commit_id}}
    call add(rows, row)

    let row.node = self._nodes.get_or_make_node_from_path(viler#Path#join(a:dir, name))
    call self._nodes.node_displayed(row.node.id, 1)
    if (get(a:opts, 'refresh_nodes', 0))
      call row.node.refresh()
    endif

    let node_path = row.node.abs_path()
    let states = get(a:opts, 'states', {})
    let row.state = get(states, node_path, {})
    if row.node.is_dir && get(row.state, 'tree_open', 0)
      let row.children = self._list_children(node_path, a:depth + 1, a:opts)
    endif
  endfor

  return sort(rows, function('s:sort_rows_by_type_and_name'))
endfunction

function! s:sort_rows_by_type_and_name(row1, row2) abort
  let n1 = a:row1.node
  let n2 = a:row2.node
  if n1.is_dir isnot# n2.is_dir
    return n2.is_dir - n1.is_dir
  endif
  if n1.name is# n2.name
    return 0
  endif
  return n1.name < n2.name ? -1 : 1
endfunction

function! s:Filer.open_cursor_file(cmd) abort
  let row = self._buf.row_info(self._buf.lnum_cursor())
  if row.is_new
    throw '[viler] This file is not saved yet'
  endif

  let node = self._get_node(row.node_id, row.commit_id)
  if node.is_dir
    call self.display(node.abs_path(), {})
    call self._buf.reset_cursor()
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

  call self.display(dir_node.dir, {})
  let lnum_prev_dir = self._buf.node_lnum(cur_dir.node_id)
  if 0 < lnum_prev_dir
    call self._buf.put_cursor(lnum_prev_dir, 1)
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

  let row = self._buf.row_info(a:lnum)
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
    call self._buf.update_row_info(node, row, {'tree_open': 0})
    call self._close_tree(node, row)
  else
    call self._buf.update_row_info(node, row, {'tree_open': 1})
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

    let row = self._buf.row_info(l)
    if row.depth <=# a:dir_row.depth
      break
    endif
    call self._nodes.node_displayed(row.node_id, 0)
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
  if curhead.seq <=# self._commit_state.undo_seq_last
    return
  endif

  call self._nodes.clear_displayed_nodes()
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

  call self._nodes.clear_displayed_nodes()
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
    let row = self._buf.row_info(l)

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
    call self._nodes.node_displayed(row.node_id, 1)
    let prev_depth = row.depth
    let prev_name = row.name

    if file_path is# a:prev_dir.path
      let prev_dir_lnum = l
    endif
  endwhile

  if 0 < prev_dir_lnum
    call self._buf.put_cursor(prev_dir_lnum, 1)
  endif
endfunction
