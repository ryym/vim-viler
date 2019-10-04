let s:Reconciler = {}

function! efiler#Reconciler#new(work_dir) abort
  let reconciler = deepcopy(s:Reconciler)

  let wd = a:work_dir
  if wd[len(wd) - 1] != '/'
    let wd .= '/'
  endif
  let reconciler._work_dir = wd

  return reconciler
endfunction

function! s:Reconciler.reconcile(changeset) abort
  let cs = a:changeset

  let copied = []
  let moved = []
  for dest in keys(cs.copied)
    let entry = cs.copied[dest]
    call add(has_key(cs.deleted, entry.src_path) ? moved : copied, entry)
  endfor

  " 1. Move to temporary directory.
  " let tmp_moves = self._move_files_tmp(moved)

  " 2. Delete
  " call self._delete_files(keys(cs.deleted))

  " 3. Move
  " call self._move_files(moved, tmp_moves)

  " " 4. Copy
  " call self._copy_files(copied)

  " " 5. Add
  " call self._add_files(keys(cs.added))
endfunction
