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

function! s:Reconciler.apply(operations) abort
  let op = a:operations

  " 1. Move to temporary directory.
  let tmp_moves = self._move_files_tmp(op.move)

  " 2. Delete
  " call self._delete_files(keys(op.delete))

  " 3. Move
  call self._move_files(op.move, tmp_moves)

  " " 4. Copy
  " call self._copy_files(op.copy)

  " " 5. Add
  " call self._add_files(keys(op.add))
endfunction

function! s:Reconciler._move_files_tmp(entries) abort
   let tmp_paths = {}
   let i = 0
   for entry in a:entries
     let i += 1
     let tmp_path = self._work_dir . i
     call rename(entry.src_path, tmp_path)
     let tmp_paths[entry.dest_path] = tmp_path
   endfor
   return tmp_paths
endfunction

function! s:Reconciler._move_files(moved, tmp_moves) abort
  for entry in a:moved
    let tmp_src = a:tmp_moves[entry.dest_path]
    call rename(tmp_src, entry.dest_path)
  endfor
endfunction
