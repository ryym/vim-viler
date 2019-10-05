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
  call self._delete_files(op.delete)

  " 3. Move
  call self._move_files(op.move, tmp_moves)

  " 4. Copy
  call self._copy_files(op.copy)

  " " 5. Add
  " call self._add_files(keys(op.add))
endfunction

function! s:Reconciler._move_files_tmp(entries) abort
   let tmp_paths = {}
   let i = 0
   for entry in a:entries
     let i += 1

     if s:ensure_file_exists(entry.src_path, 'move') == s:FILE_TYPE.NOT_EXIST
       continue
     endif

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

" TODO: Move files into some temporary directory
" instead of actually deleting them to make them restorable.
" (and make this behavior optional)
function! s:Reconciler._delete_files(paths) abort
  for path in a:paths
    let type = s:ensure_file_exists(path, 'delete')
    if type == s:FILE_TYPE.DIR
      call delete(path, "rf")
    elseif type == s:FILE_TYPE.FILE
      call delete(path)
    endif
  endfor
endfunction

function! s:Reconciler._copy_files(entries) abort
  for entry in a:entries
    if s:ensure_file_exists(entry.src_path, 'copy') == s:FILE_TYPE.NOT_EXIST
      continue
    endif

    " TODO: Make it cross-platform.
    let output = system('cp ' . shellescape(entry.src_path) . ' ' . shellescape(entry.dest_path))
    if v:shell_error != 0
      throw output
    endif
  endfor
endfunction

let s:FILE_TYPE = {'NOT_EXIST': 0, 'DIR': 1, 'FILE': 2}

" If the file does not exists, it prints a warning message.
function! s:ensure_file_exists(path, operation) abort
  if isdirectory(a:path)
    return s:FILE_TYPE.DIR
  elseif filereadable(a:path)
    return s:FILE_TYPE.FILE
  endif

  echom '[efiler] file not found to ' . a:operation . ': ' . a:path . '. something wrong.'
  return s:FILE_TYPE.NOT_EXIST
endfunction
