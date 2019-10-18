let s:Diff = {}

function! viler#diff#Diff#new(tree, id_gen) abort
  let diff = deepcopy(s:Diff)
  let diff._tree = a:tree
  let diff._move_id = a:id_gen
  let diff.dirops = {}
  let diff.moves = {}
  let diff.deletions = {}
  return diff
endfunction

function! s:Diff.register_dirs_from_path(path) abort
  return self._tree.register_dirs_from_path(a:path)
endfunction

function! s:Diff.get_or_make_node(parent_id, name, is_dir) abort
  return self._tree.get_or_make_node(a:parent_id, a:name, a:is_dir)
endfunction

function! s:Diff.try_get_dirop(dir_id) abort
  return get(self.dirops, a:dir_id, 0)
endfunction

" TODO: Rename to get_dirop
function! s:Diff.dirop(dir_id) abort
  let op = self.try_get_dirop(a:dir_id)
  if type(op) == v:t_number
    throw '[viler] No operations for ' . a:dir_id
  endif
  return op
endfunction

function! s:Diff.new_file(parent_id, name, stat) abort
  let file = self.get_or_make_node(a:parent_id, a:name, a:stat.is_dir)
  let op = self._get_or_make_op(a:parent_id)
  call add(op.add, file.id)
endfunction

function! s:Diff.moved_file(parent_id, name, src) abort
  let path = a:src.abs_path
  let src_parent_path = fnamemodify(path, ':h')
  let src_parent_dir = self.register_dirs_from_path(src_parent_path)

  let src_node = self.get_or_make_node(src_parent_dir.id, a:src.name, a:src.is_dir)
  let dest_node = self.get_or_make_node(a:parent_id, a:name, a:src.is_dir)

  let move_id = self._move_id.make_id()
  let move_entry = {
    \   'id': move_id,
    \   'src_id': src_node.id,
    \   'dest_id': dest_node.id,
    \   'is_copy': 0,
    \   'done': 0,
    \ }
  let self.moves[move_id] = move_entry

  let src_parent_op = self._get_or_make_op(src_parent_dir.id)
  call add(src_parent_op.move_to, move_id)

  let dest_parent_op = self._get_or_make_op(a:parent_id)
  call add(dest_parent_op.move_from, move_id)
endfunction

function! s:Diff.deleted_file(parent_id, name, stat) abort
  let file = self.get_or_make_node(a:parent_id, a:name, a:stat.is_dir)
  let op = self._get_or_make_op(a:parent_id)
  let op.delete[file.id] = 1
  let self.deletions[file.id] = 1
endfunction

function! s:Diff._get_or_make_op(dir_id) abort
  " Use get_dir to ensure that the given id's node is a directory.
  let dir = self._tree.get_dir(a:dir_id)
  let op = get(self.dirops, dir.id, {})
  if !has_key(op, 'dir_id')
    let op = s:new_dirop(dir.id)
    let self.dirops[dir.id] = op
  endif
  return op
endfunction

function! s:new_dirop(dir_id) abort
  return {
    \   'dir_id': a:dir_id,
    \   'add': [],
    \   'move_from': [],
    \   'move_to': [],
    \   'delete': {},
    \  }
endfunction

function! s:Diff.merge(other) abort
  for op in values(a:other.dirops)
    let my_op = self._get_or_make_op(op.dir_id)
    call s:merge_ops(my_op, op)
  endfor
  call s:merge_dict(self.moves, a:other.moves)
  call s:merge_dict(self.deletions, a:other.deletions)
endfunction

function! s:Diff.unify_nodes_for_move(src_id, dest_id) abort
  let src = self._tree.get_node(a:src_id)
  if !src.is_dir
    return
  endif

  let dest = self._tree.get_node(a:dest_id)
  for child_id in values(dest.children)
    let child = self._tree.get_node(child_id)
    let child.parent = src.id
  endfor
  call s:merge_dict(src.children, dest.children)
  let dest.children = {}

  let src_op = self._get_or_make_op(a:src_id)
  let dest_op = self._get_or_make_op(a:dest_id)
  call s:merge_ops(src_op, dest_op)
  call remove(self.dirops, a:dest_id)
endfunction

function! s:merge_ops(op1, op2) abort
  call s:append_list(a:op1.add, a:op2.add)
  call s:append_list(a:op1.move_from, a:op2.move_from)
  call s:append_list(a:op1.move_to, a:op2.move_to)
  call s:merge_dict(a:op1.delete, a:op2.delete)
endfunction

function! s:append_list(l1, l2) abort
  for item in a:l2
    call add(a:l1, item)
  endfor
endfunction

function! s:merge_dict(d1, d2) abort
  for key in keys(a:d2)
    let a:d1[key] = a:d2[key]
  endfor
endfunction
