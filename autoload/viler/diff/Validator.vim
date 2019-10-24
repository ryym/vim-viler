let s:Validator = {}

function! viler#diff#Validator#new() abort
  let validator = deepcopy(s:Validator)
  return validator
endfunction

function! s:Validator.validate_diff(diff) abort
  let errs = self.validate_duplicate_dests(a:diff.moves)
  if len(errs) > 0
    return errs
  endif

  let errs = self.validate_dirty_nests(a:diff)
  if len(errs) > 0
    return errs
  endif

  let errs = self.validate_dir_contents(a:diff)

  return errs
endfunction

function! s:Validator.validate_duplicate_dests(moves) abort
  let errs = {}
  let dup_dests = self._find_duplicate_dests(a:moves)

  if len(dup_dests) > 0
    for dd in dup_dests
      let errs[dd.dest_path] = 'Duplicate copy/move from: ' . join(dd.src_paths, ', ')
    endfor
  endif

  return errs
endfunction

function! s:Validator.validate_dirty_nests(diff) abort
  let dirty_dirs = {}

  for move in values(a:diff.moves)
    let dirty_dirs[move.src_path] = 1
    let dirty_dirs[move.dest_path] = 1
  endfor
  for op in values(a:diff.dirops)
    for path in keys(op.delete)
      let dirty_dirs[path] = 1
    endfor
  endfor

  let dirty_dirs = keys(dirty_dirs)

  let errs = {}
  for op in values(a:diff.dirops)
    for dir in dirty_dirs
      let is_ancestor = op.path == dir || stridx(op.path, dir . '/') == 0
      if is_ancestor
        let errs[dir] = 'It is not supported yet to edit files inside of edited directory'
      endif
    endfor
  endfor

  return errs
endfunction

function! s:Validator._find_duplicate_dests(moves) abort
  let dups = []
  let dest2srcs = {}
  for move in values(a:moves)
    let srcs = get(dest2srcs, move.dest_path, {})
    let srcs[move.src_path] = 1
    let dest2srcs[move.dest_path] = srcs
    if len(srcs) == 2
      call add(dups, move.dest_path)
    endif
  endfor
  return dups->map({_, d -> {'dest_path': d, 'src_paths': keys(dest2srcs[d])}})
endfunction

function! s:Validator.validate_dir_contents(diff) abort
  let errs = {}
  for op in values(a:diff.dirops)
    call self._validate_dirop(a:diff, op, errs)
  endfor
  return errs
endfunction

function! s:Validator._validate_dirop(diff, op, errs) abort
  let files = {}
  let dir_path = a:op.path

  for name in readdir(dir_path)
    let full_path = dir_path . '/' . name
    let is_dir = isdirectory(full_path)
    let files[full_path] = 1
  endfor

  for move_id in a:op.move_to
    let move = a:diff.moves[move_id]
    if !move.is_copy
      call remove(files, move.src_path)
    endif
  endfor

  for path in keys(a:op.delete)
    call remove(files, path)
  endfor

  let added_files = copy(a:op.add)->map('v:val.path')
  for move_id in a:op.move_from
    let move = a:diff.moves[move_id]
    call add(added_files, move.dest_path)
  endfor

  for path in added_files
    if has_key(files, path)
      let file = files[path]
      let msgs = get(a:errs, dir_path, [])
      call add(msgs, 'Duplicate path: ' . fnamemodify(path, ':t'))
      let a:errs[dir_path] = msgs
    else
      let files[path] = path
    endif
  endfor
endfunction
