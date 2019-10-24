let s:Unifier = {}

function! viler#diff#Unifier#new(id_gen) abort
  let unifier = deepcopy(s:Unifier)
  let unifier._id_gen = a:id_gen
  return unifier
endfunction

function! s:Unifier.unify_diffs(diffs) abort
  let diff = viler#diff#Diff#new(self._id_gen)
  for d in a:diffs
    call diff.merge(d)
  endfor

  for move in values(diff.moves)
    if !has_key(diff.deletions, move.src_path)
      let move.is_copy = 1
      continue
    endif
    call remove(diff.deletions, move.src_path)

    let src_parent = fnamemodify(move.src_path, ':h')
    let op = diff.dirops[src_parent]
    call remove(op.delete, move.src_path)
  endfor

  return diff
endfunction

" function! s:Unifier.
