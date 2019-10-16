let s:Unifier = {}

function! viler#diff#Unifier#new(tree, id_gen, validator) abort
  let unifier = deepcopy(s:Unifier)
  let unifier._tree = a:tree
  let unifier._id_gen = a:id_gen
  let unifier._validator = a:validator
  return unifier
endfunction

function! s:Unifier.unify_diffs(diffs) abort
  let diff = self._merge_diffs(a:diffs)

  let errs = self._validator.validate_copies(diff.copies)
  if len(errs) > 0
    return { 'error': errs }
  endif

  let moves = self._detect_moves(diff)
  for mv in moves
    call diff.unify_nodes_for_move(mv.src_id, mv.dest_id)
  endfor

  let errs = self._validator.validate_dirs(diff)
  if len(errs) > 0
    return { 'error': errs }
  endif

  return { 'ok': diff }
endfunction

function! s:Unifier._merge_diffs(diffs) abort
  let diff = viler#diff#Diff#new(self._tree, self._id_gen)
  for d in a:diffs
    call diff.merge(d)
  endfor
  return diff
endfunction

function! s:Unifier._detect_moves(diff) abort
  let moves = []
  for copy in values(a:diff.copies)
    if !has_key(a:diff.deletions, copy.src_id)
      continue
    endif
    let src = self._tree.get_node(copy.src_id)
    let src_parent = self._tree.get_node(src.parent)
    let op = a:diff.dirop(src_parent.id)
    call add(op.move_away, copy.id)
    call remove(op.delete, copy.src_id)
    call remove(a:diff.deletions, copy.src_id)
    let copy.is_move = 1
    call add(moves, copy)
  endfor
  return moves
endfunction
