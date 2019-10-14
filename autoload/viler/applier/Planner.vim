let s:Planner = {}

function! viler#applier#Planner#new(id_gen, work_dir_path) abort
  let planner = deepcopy(s:Planner)
  let planner._id_gen = a:id_gen
  let planner._work_dir_path = a:work_dir_path
  return planner
endfunction

" TODO: Support multiple diffs.
" function! s:Planner.make_plan(diff) abort
"   " Detect moves.
"   for copy in values(a:diff.copies)
"     let del_id = copy.src.id . '_' . copy.src.name
"     if has_key(a:diff.deletions, del_id)
"       let src_parent = a:diff.dirs[copy.src.id]
"       call add(src_parent.changes.move_away, copy.id)
"       call remove(src_parent.changes.delete, copy.src.name)
"     endif
"   endfor

"   let plan = {'dirs': a:diff.dirs, 'copies': a:diff.copies}

"   let work_dir = viler#applier#Diff#new_dir(-10, -1, self._work_dir_path)
"   let plan.dirs[-10] = work_dir

"   return plan
" endfunction

" TODO: Support multiple diffs.
function! s:Planner.make_plan(diff) abort
  " Detect moves.
  for copy in values(a:diff.copies)
    if has_key(a:diff.deletions, copy.src_id)
      let src = a:diff.get_node(copy.src_id)
      let src_parent = a:diff.get_node(src.parent)
      call add(src_parent.changes.move_away, copy.id)
      call remove(src_parent.changes.delete, copy.src_id)
      call remove(a:diff.deletions, copy.src_id)
      let copy.is_move = 1
    endif
  endfor

  " XXX: plan or diff_tree?
  let work_dir = a:diff.make_node(-1, self._work_dir_path, 1)
  return a:diff
endfunction
