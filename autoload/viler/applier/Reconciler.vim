let s:Reconciler = {}

function! viler#applier#Reconciler#new(diff_tree, fs) abort
  let reconciler = deepcopy(s:Reconciler)
  let reconciler._diff = a:diff_tree
  let reconciler._fs = a:fs
  let reconciler._work_file_id = 0
  return reconciler
endfunction

function! s:Reconciler.apply_changes() abort
  call self._apply_changes(1)
endfunction

function! s:Reconciler._apply_changes(dir_id) abort
  let dir = self._diff.get_node(a:dir_id)
  if !dir.is_dir
    return
  endif

  let changes = dir.changes

  for node_id in keys(changes.delete)
    call self._delete_file(node_id)
  endfor

  for copy_id in changes.move_away
    call self._move_file_away(dir, copy_id)
  endfor

  for copy_id in changes.copy_from
    call self._copy_file_to(dir, copy_id)
  endfor

  for node_id in changes.add
    call self._add_file(node_id)
  endfor

  for child_id in values(dir.children)
    call self._apply_changes(child_id)
  endfor
endfunction

function! s:Reconciler._dir(dir_id) abort
  return self._diff.dirs[a:dir_id]
endfunction

function! s:Reconciler._copy_entry(copy_id) abort
  return self._diff.copies[a:copy_id]
endfunction

function! s:Reconciler._make_path(node) abort
  let node = a:node
  let parts = [node.name]
  while node.parent != -1
    let node = self._diff.get_node(node.parent)
    call add(parts, node.name)
  endwhile
  return parts->reverse()->join('/')
endfunction

function! s:Reconciler._new_work_file() abort
  let self._work_file_id += 1

  " XXX: Temporary.
  let work_dir_id = self._diff.nodes->keys()->max()
  let work_dir = self._diff.get_dir(work_dir_id)
  " let work_file = self._diff.make_node(work_dir_id, self._work_file_id)

  return {
    \   'dir_id': work_dir_id,
    \   'path': self._make_path(work_dir) . '/' . self._work_file_id,
    \   'name': self._work_file_id,
    \ }
endfunction

function! s:Reconciler._delete_file(node_id) abort
  let node = self._diff.get_node(a:node_id)
  let path = self._make_path(node)

  " Just move the file instead of actually deleting it.
  let work_file = self._new_work_file()
  call self._fs.move_file(path, work_file.path)
endfunction

function! s:Reconciler._move_file_away(src_parent, copy_id) abort
  let copy = self._copy_entry(a:copy_id)
  if copy.done
    return
  endif

  let src_node = self._diff.get_node(copy.src_id)

  let work_file = self._new_work_file()

  let src_path = self._make_path(src_node)
  call self._fs.move_file(src_path, work_file.path)

  let src_parent = self._diff.get_node(src_node.parent)

  " Move the src node to the child node of work directory.
  call remove(src_parent.children, src_node.name)
  let work_dir = self._diff.get_node(work_file.dir_id)
  let src_node.parent = work_dir.id
  let src_node.name = work_file.name
  let work_dir.children[src_node.name] = src_node.id
endfunction

function! s:Reconciler._copy_file_to(_dest_parent, copy_id) abort
  let copy = self._copy_entry(a:copy_id)

  let src_node = self._diff.get_node(copy.src_id)
  let src_parent = self._diff.get_node(src_node.parent)

  let src_path = self._make_path(src_node)
  let dest_node = self._diff.get_node(copy.dest_id)
  let dest_path = self._make_path(dest_node)

  if copy.is_move
    call self._fs.move_file(src_path, dest_path)

    " Replace the dest node with the src node.
    " TODO: To do this, the dest node must not be referenced by nobody.
    let dest_parent = self._diff.get_node(dest_node.parent)
    let dest_parent.children[dest_node.name] = src_node.id
    call remove(src_parent.children, src_node.name)
    let src_node.parent = dest_parent.id
    let src_node.name = dest_node.name
  else
    call self._fs.copy_file(src_path, dest_path)
  endif
  let copy.done = 1
endfunction

function! s:Reconciler._add_file(node_id) abort
  let node = self._diff.get_node(a:node_id)
  let path = self._make_path(node)
  if node.is_dir
    call self._fs.make_dir(path)
  else
    call self._fs.make_file(path)
  endif
endfunction

