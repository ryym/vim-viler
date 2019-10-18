let s:Applier = {}

function! viler#diff#Applier#new(tree, diff, fs, work_dir) abort
  let applier = deepcopy(s:Applier)
  let applier._tree = a:tree
  let applier._diff = a:diff
  let applier._fs = a:fs
  let applier._work_dir = a:work_dir
  let applier._work_dir_node_id = 0
  let applier._work_file_id = 0
  return applier
endfunction

function! s:Applier.apply_changes() abort
  let root = self._tree.root_dir()

  " Prepare the working directory.
  call self._fs.make_dir(self._work_dir.path)
  let node = self._tree.make_node(root.id, self._work_dir.path_from_root, 1)
  let self._work_dir_node_id = node.id

  call self._apply_changes(root.id)
endfunction

function! s:Applier._apply_changes(dir_id) abort
  let dir = self._tree.get_node(a:dir_id)
  if !dir.is_dir
    return
  endif

  let op = self._diff.try_get_dirop(dir.id)

  if type(op) != v:t_number
    for node_id in keys(op.delete)
      call self._delete_file(node_id)
    endfor

    for move_id in op.move_to
      call self._move_file_away(dir, move_id)
    endfor

    for move_id in op.move_from
      call self._move_file_to(dir, move_id)
    endfor

    for node_id in op.add
      call self._add_file(node_id)
    endfor
  endif

  for child_id in values(dir.children)
    call self._apply_changes(child_id)
  endfor
endfunction

function! s:Applier._move_entry(move_id) abort
  return self._diff.moves[a:move_id]
endfunction

function! s:Applier._new_work_file() abort
  let self._work_file_id += 1

  let work_dir = self._tree.get_dir(self._work_dir_node_id)

  return {
    \   'dir_id': work_dir.id,
    \   'path': self._tree.path(work_dir) . '/' . self._work_file_id,
    \   'name': self._work_file_id,
    \ }
endfunction

function! s:Applier._delete_file(node_id) abort
  let node = self._tree.get_node(a:node_id)
  let path = self._tree.path(node)

  " Just move the file instead of actually deleting it for now.
  let work_file = self._new_work_file()
  call self._fs.move_file(path, work_file.path)

  call self._tree.remove_node(node.id)
endfunction

function! s:Applier._move_file_away(src_parent, move_id) abort
  let move = self._move_entry(a:move_id)
  if move.done
    return
  endif

  let src_node = self._tree.get_node(move.src_id)
  let src_path = self._tree.path(src_node)
  let work_file = self._new_work_file()

  if move.is_copy
    call self._fs.copy_file(src_path, work_file.path)
    let copied_src = self._tree.make_node(work_file.dir_id, work_file.name, src_node.is_dir)
    let move.src_id = copied_src.id
    let move.done = 1
  else
    call self._fs.move_file(src_path, work_file.path)
    call self._tree.move_node(src_node.id, work_file.dir_id, work_file.name)
  endif
endfunction

function! s:Applier._move_file_to(dest_parent, move_id) abort
  let move = self._move_entry(a:move_id)

  let src_node = self._tree.get_node(move.src_id)
  let src_parent = self._tree.get_node(src_node.parent)

  let src_path = self._tree.path(src_node)
  let dest_node = self._tree.get_node(move.dest_id)
  let dest_path = self._tree.path(dest_node)

  if move.is_copy
    if move.done
      call self._fs.move_file(src_path, dest_path)
    else
      call self._fs.copy_file(src_path, dest_path)
    endif
  else
    call self._fs.move_file(src_path, dest_path)

    " The dest node may not be exist if it was an existing file and
    " was deleted or moved by another operation.
    if has_key(a:dest_parent.children, dest_node.name)
      " If it exists, it is a new file created at this time.
      " In that case it must be safe to remove the dest node because:
      " - the file corresponding to the dest node does not exist yet
      "   so it cannot be a src of another move entry.
      " - duplicate dest is invalid so it cannot be a dest of another move entry.
      call self._tree.remove_node(dest_node.id)
    endif
    call self._tree.move_node(src_node.id, dest_node.parent, dest_node.name)
  endif

  let move.done = 1
endfunction

function! s:Applier._add_file(node_id) abort
  let node = self._tree.get_node(a:node_id)
  let path = self._tree.path(node)
  if node.is_dir
    call self._fs.make_dir(path)
  else
    call self._fs.make_file(path)
  endif
endfunction

