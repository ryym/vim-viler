let s:Diff = {}

function! viler#diff#Diff#new(id_gen) abort
  let diff = deepcopy(s:Diff)
  let diff._move_id = a:id_gen
  let diff.dirops = {}
  let diff.moves = {}
  let diff.deletions = {}
  return diff
endfunction

function! s:Diff.new_file(path, name, stat) abort
  let op = self._get_or_make_op(a:path)
  call add(op.add, {'path': viler#Path#join(a:path, a:name), 'is_dir': a:stat.is_dir})
endfunction

function! s:Diff.moved_file(path, name, src) abort
  let dest_path = viler#Path#join(a:path, a:name)
  let src_parent_path = fnamemodify(a:src.abs_path, ':h')

  let move_id = self._move_id.make_id()
  let move_entry = {
    \   'id': move_id,
    \   'src_path': a:src.abs_path,
    \   'dest_path': dest_path,
    \   'is_copy': 0,
    \ }
  let self.moves[move_id] = move_entry

  let src_parent_op = self._get_or_make_op(src_parent_path)
  call add(src_parent_op.move_to, move_id)

  let dest_parent_op = self._get_or_make_op(a:path)
  call add(dest_parent_op.move_from, move_id)
endfunction

function! s:Diff.deleted_file(path, name, stat) abort
  let op = self._get_or_make_op(a:path)
  let abs_path = viler#Path#join(a:path, a:name)
  let op.delete[abs_path] = {'path': abs_path, 'is_dir': a:stat.is_dir}
  let self.deletions[abs_path] = 1
endfunction

function! s:Diff._get_or_make_op(path) abort
  let op = get(self.dirops, a:path, {})
  if !has_key(op, 'path')
    let op = s:new_dirop(a:path)
    let self.dirops[a:path] = op
  endif
  return op
endfunction

function! s:new_dirop(path) abort
  return {
    \   'path': a:path,
    \   'add': [],
    \   'move_from': [],
    \   'move_to': [],
    \   'delete': {},
    \  }
endfunction

function! s:Diff.merge(other) abort
  for op in values(a:other.dirops)
    let my_op = self._get_or_make_op(op.path)
    call s:merge_ops(my_op, op)
  endfor
  call s:merge_dict(self.moves, a:other.moves)
  call s:merge_dict(self.deletions, a:other.deletions)
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

