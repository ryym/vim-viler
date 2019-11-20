let s:Applier = {}

function! viler#diff#Applier#new(diff, fs, work_dir) abort
  let applier = deepcopy(s:Applier)
  let applier._diff = a:diff
  let applier._fs = a:fs
  let applier._work_dir = a:work_dir
  let applier._work_file_id = 0
  return applier
endfunction

function! s:Applier.apply_changes() abort
  for move in values(self._diff.moves)
    if move.is_copy
      let work_path = self._new_work_file().path
      call self._fs.copy_file(move.src_path, work_path)
      let move.src_path = work_path
    endif
  endfor

  for move in values(self._diff.moves)
    if !move.is_copy
      let work_path = self._new_work_file().path
      call self._fs.move_file(move.src_path, work_path)
      let move.src_path = work_path
    endif
  endfor

  let dirops = values(self._diff.dirops)
  call sort(dirops, funcref('s:sort_ops_by_path_depth'))

  for op in dirops
    for path in keys(op.delete)
      " For now we do not actually delete a file for safety.
      let work_path = self._new_work_file().path
      call self._fs.move_file(path, work_path)
    endfor

    for move_id in op.move_from
      let move = self._diff.moves[move_id]
      call self._fs.move_file(move.src_path, move.dest_path)
    endfor

    for file in op.add
      if file.is_dir
        call self._fs.make_dir(file.path)
      else
        call self._fs.make_file(file.path)
      endif
    endfor
  endfor
endfunction

function! s:Applier._new_work_file() abort
  let self._work_file_id += 1
  let path = viler#Path#join(self._work_dir.path, self._work_file_id)
  return {'path': path}
endfunction

function! s:sort_ops_by_path_depth(op1, op2) abort
  let depth1 = s:count_dirs(a:op1.path)
  let depth2 = s:count_dirs(a:op2.path)
  return depth1 - depth2
endfunction

function! s:count_dirs(path) abort
  let cnt = 0
  let size = strchars(a:path)
  let i = 0
  while i < size
    if strcharpart(a:path, i, 1) is# '/'
      let cnt += 1
    endif
    let i += 1
  endwhile
  return cnt
endfunction
