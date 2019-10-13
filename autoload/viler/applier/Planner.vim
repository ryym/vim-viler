let s:Planner = {}

function! viler#applier#Planner#new() abort
  let planner = deepcopy(s:Planner)
  return planner
endfunction

" TODO: Support multiple diffs.
function! s:Planner.make_plan(diff) abort
  " Detect moves.
  for copy in values(a:diff.copies)
    let del_id = copy.src.id . '_' . copy.src.name
    if has_key(a:diff.deletions, del_id)
      let src_parent = a:diff.dirs[copy.src.id]
      call add(src_parent.changes.move_away, copy.id)
      call remove(src_parent.changes.delete, copy.src.name)
    endif
  endfor

  return {'dirs': a:diff.dirs, 'copies': a:diff.copies}
endfunction
