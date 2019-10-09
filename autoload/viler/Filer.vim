let s:Filer = {}

function! viler#Filer#new(id, buf, node_store, diff_checker) abort
  let filer = deepcopy(s:Filer)
  let filer._buf = a:buf
  let filer._id = a:id
  let filer._diff_checker = a:diff_checker
  let filer._nodes = a:node_store
  return filer
endfunction

function! s:Filer.display(dir) abort
  call self._nodes.clear()

  let dir_node = self._nodes.make(a:dir)
  let nodes = self._list_children(a:dir)
  call self._buf.display_nodes(dir_node, nodes)
  call self._buf.reset_cursor()

  return {'dir': dir_node, 'nodes': nodes}
endfunction

function! s:Filer._list_children(dir) abort
  let nodes = []
  for name in readdir(a:dir)
    let node = self._nodes.make(a:dir . '/' . name)
    call add(nodes, node)
  endfor
  return sort(nodes, function('s:sort_nodes_by_type_and_name'))
endfunction

function! s:sort_nodes_by_type_and_name(a, b) abort
  if a:a.is_dir != a:b.is_dir
    return a:b.is_dir - a:a.is_dir
  endif
  if a:a.name == a:b.name
    return 0
  endif
  return a:a.name < a:b.name ? -1 : 1
endfunction

function! s:Filer.go_down_cursor_dir() abort
  let row = self._buf.node_row(self._buf.lnum_cursor())
  if row.is_dir
    let node = self._nodes.get(row.node_id)
    call self.display(node.abs_path())
  endif
endfunction

function! s:Filer.go_up_dir() abort
  let dir_id = self._buf.current_dir().node_id
  let dir_node = self._nodes.get(dir_id)
  let shown_nodes = self.display(dir_node.dir)

  let prev_dir_node_id = 0
  for node in shown_nodes.nodes
    if node.name == dir_node.name
      let prev_dir_node_id = node.id
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

function! s:Filer.toggle_tree() abort
  " TODO: Prevent toggling of edited directory.
  let row = self._buf.node_row(self._buf.lnum_cursor())
  if !row.is_dir
    return
  endif

  let node = self._nodes.get(row.node_id)
  if row.state.tree_open
    call self._buf.update_node_row(node, row, {'tree_open': 0})
    call self._close_tree(node, row)
  else
    call self._buf.update_node_row(node, row, {'tree_open': 1})
    let nodes = self._list_children(node.abs_path())
    call self._buf.append_nodes(row.lnum, nodes, row.depth + 1)
  endif

  call self._buf.save()
endfunction

function! s:Filer._close_tree(dir_node, dir_row) abort
  let last_lnum = self._buf.lnum_last()
  let l = a:dir_row.lnum
  while l < last_lnum
    let l += 1
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

  let cur_dir = self._buf.current_dir()
  call self._nodes.clear()
  call self._buf.undo()
  call self._restore_nodes_on_buf(cur_dir)
  call self._buf.save()
endfunction

function! s:Filer.redo() abort
  if self._buf.modified()
    call self._buf.redo()
    return
  endif

  let cur_dir = self._buf.current_dir()
  call self._nodes.clear()
  let modified = self._buf.redo()
  call self._restore_nodes_on_buf(cur_dir)

  if !modified
    call self._buf.save()
  endif
endfunction

function! s:Filer._restore_nodes_on_buf(prev_dir) abort
  let cur_dir = self._buf.current_dir()
  call self._nodes.get_or_make(cur_dir.node_id, cur_dir.path)

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
      let dir_path = fnamemodify(dir_path, ':h')
    endif

    let file_path = dir_path . '/' . row.name
    call self._nodes.get_or_make(row.node_id, file_path)
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

function! s:Filer.gather_changes() abort
  return self._diff_checker.gather_changes(self._buf, self._nodes)
endfunction
