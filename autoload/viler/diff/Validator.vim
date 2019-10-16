let s:Validator = {}

" TODO: Should prevent edition inside of a deleted directory
" (It can happen with multiple filers).

function! viler#diff#Validator#new(tree) abort
  let validator = deepcopy(s:Validator)
  let validator._tree = a:tree
  return validator
endfunction

function! s:Validator.validate_copies(copies) abort
  let errs = {}
  let dup_dests = self._find_duplicate_dests(a:copies)
  for dd in dup_dests
    let dest = self._tree.get_node(dd.dest_id)
    let dest_path = self._tree.path(dest)
    let src_paths = dd.src_ids->map({_, id -> self._tree.path(self._tree.get_node(id))})
    let errs[dest_path] = 'Duplicate copy/move from: ' . join(src_paths, ', ')
  endfor
  return errs
endfunction

function! s:Validator._find_duplicate_dests(copies) abort
  let dups = []
  let dest2srcs = {}
  for copy in values(a:copies)
    let srcs = get(dest2srcs, copy.dest_id, [])
    call add(srcs, copy.src_id)
    let dest2srcs[copy.dest_id] = srcs
    if len(srcs) == 2
      call add(dups, copy.dest_id)
    endif
  endfor
  return dups->map({_, d -> {'dest_id': d, 'src_ids': dest2srcs[d]}})
endfunction

function! s:Validator.validate_dirs(diff) abort
  let errs = {}
  let dir = self._tree.root_dir()
  call self._validate_dir(a:diff, dir, '/', errs)
  return errs
endfunction

function! s:Validator._validate_dir(diff, dir, path, errs) abort
  let op = a:diff.try_get_dirop(a:dir.id)
  if type(op) != v:t_number
    call self._validate_dirop(a:diff, a:path, op, a:errs)
  endif
  for child_id in values(a:dir.children)
    let child = self._tree.get_node(child_id)
    if child.is_dir
      call self._validate_dir(a:diff, child, a:path . '/' . child.name, a:errs)
    endif
  endfor
endfunction

function! s:Validator._validate_dirop(diff, path, op, errs) abort
  let files = {}
  for name in readdir(a:path)
    let is_dir = isdirectory(a:path . '/' . name)
    let files[name] = {'name': name, 'is_dir': is_dir, 'is_new': 0}
  endfor

  for copy_id in a:op.move_away
    let move = a:diff.copies[copy_id]
    let name = self._tree.get_node(move.src_id).name
    call remove(files, name)
  endfor

  for dl_id in keys(a:op.delete)
    let name = self._tree.get_node(dl_id).name
    call remove(files, name)
  endfor

  let added_files = copy(a:op.add)->map('self._tree.get_node(v:val)')
  for copy_id in a:op.copy_from
    let copy = a:diff.copies[copy_id]
    let node = self._tree.get_node(copy.dest_id)
    call add(added_files, node)
  endfor

  for node in added_files
    if has_key(files, node.name)
      let file = files[node.name]
      if !file.is_new || file.is_dir != node.is_dir
        let msgs = get(a:errs, a:path, [])
        call add(msgs, 'Duplicate path: ' . a:path . '/' . file.name)
        let a:errs[a:path] = msgs
      endif
    else
      let files[node.name] = {'name': node.name, 'is_dir': node.is_dir, 'is_new': 1}
    endif
  endfor
endfunction

