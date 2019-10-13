let s:DiffMaker = {}

function! viler#applier#DiffMaker#new(node_store, id_gen) abort
  let maker = deepcopy(s:DiffMaker)
  let maker._node_store = a:node_store
  let maker._dir_id_gen = a:id_gen
  return maker
endfunction

function! s:DiffMaker.gen_diff(buf) abort
  let dir_path = a:buf.current_dir().path
  let diff = viler#applier#Diff#new(self._dir_id_gen)
  let root = diff.register_dirs_from_path(dir_path)
  let dir = {
    \   'lnum': 1,
    \   'is_new': 0,
    \   'id': root.id,
    \   'path': dir_path,
    \   'depth': 0,
    \ }
  call self._gather_changes(a:buf, dir, diff)
  return diff
endfunction

function! s:DiffMaker._gather_changes(buf, dir, diff) abort
  let l = a:dir.lnum
  let last_lnum = a:buf.lnum_last()
  let unchanged_files = {}

  while l < last_lnum
    let l += 1

    let row = a:buf.node_row(l)
    if row.depth < a:dir.depth
      break
    endif

    if row.depth != a:dir.depth
      echom string([a:dir, row])
      throw '[vfiler] Wierd indentation at line ' . row.lnum . ': ' . row.name
    endif

    if row.is_new
      if row.name == ''
        continue
      endif
      call a:diff.new_file(a:dir.id, row.name, {'is_dir': row.is_dir})

      " XXX: What about tree_open state?
      " Probably we need to determine the directory is open or not by
      " an indentation of the next line.
      if row.is_dir
        let dir = s:next_dir_ctx(l, a:dir, row, a:diff)
        let l = self._gather_changes(a:buf, dir, a:diff)
      endif
      continue
    endif

    let node = self._node_store.get_node(a:buf.nr(), row.node_id)
    let row_path = a:dir.path . '/' . row.name
    let src_path = node.abs_path()
    if has_key(a:dir, 'subroot')
      let src_path = substitute(src_path, a:dir.subroot.src, a:dir.subroot.dest, '')
    endif

    if src_path == row_path
      let unchanged_files[row.name] = 1
      if row.is_dir && row.state.tree_open
        let dir = s:next_dir_ctx(l, a:dir, row, a:diff)
        let l = self._gather_changes(a:buf, dir, a:diff)
      endif
      continue
    endif

    call a:diff.copied_file(a:dir.id, row.name, {
      \   'abs_path': src_path,
      \   'name': node.name,
      \   'is_dir': node.is_dir,
      \ })
    if row.is_dir && row.state.tree_open
      let dir = s:next_dir_ctx(l, a:dir, row, a:diff)
      let dir.subroot = { 'src': src_path, 'dest': row_path }
      let l = self._gather_changes(a:buf, dir, a:diff)
    endif
  endwhile

  if !a:dir.is_new
    call s:detect_deleted_files(a:dir, unchanged_files, a:diff)
  endif

  return l - 1
endfunction

function! s:detect_deleted_files(dir, unchanged_files, diff) abort
  let path = a:dir.path
  if has_key(a:dir, 'subroot')
    let path = substitute(path, a:dir.subroot.dest, a:dir.subroot.src, '')
  endif

  let real_files = readdir(path)
  for name in real_files
    if !has_key(a:unchanged_files, name)
      call a:diff.deleted_file(a:dir.id, name)
    endif
  endfor
endfunction

function! s:next_dir_ctx(l, dir, row, diff) abort
  return {
    \   'lnum': a:l,
    \   'is_new': a:row.is_new,
    \   'id': a:diff.get_or_make_dir(a:dir.id, a:row.name).id,
    \   'path': a:dir.path . '/' . a:row.name,
    \   'depth': a:dir.depth + 1,
    \ }
endfunction
