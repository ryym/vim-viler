let s:Maker = {}

function! viler#diff#Maker#new(node_store) abort
  let maker = deepcopy(s:Maker)
  let maker._node_store = a:node_store
  return maker
endfunction

function! s:Maker.is_dirty(buf, dir) abort
  let id_gen = viler#IdGen#new()
  let diff = viler#diff#Diff#new(id_gen)
  if !has_key(a:dir, 'lnum')
    let a:dir.lnum = a:buf.lnum_first() - 1
  endif
  call self._gather_changes(a:buf, a:dir, diff)
  return !diff.is_empty()
endfunction

function! s:Maker.gather_changes(buf, diff) abort
  let dir_path = a:buf.current_dir().path
  let dir = {
    \   'lnum': a:buf.lnum_first() - 1,
    \   'path': dir_path,
    \   'depth': 0,
    \ }
  call self._gather_changes(a:buf, dir, a:diff)
endfunction

function! s:Maker._gather_changes(buf, dir, diff) abort
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
      throw '[vfiler] Wierd indentation at line ' . row.lnum . ': ' . row.name
    endif

    if row.is_new
      if row.name != ''
        call a:diff.new_file(a:dir.path, row.name, {'is_dir': row.is_dir})
      endif
      continue
    endif

    let node = self._node_store.get_node(row.bufnr, row.node_id)
    let row_path = a:dir.path . '/' . row.name
    let src_path = node.abs_path()

    if src_path == row_path
      let unchanged_files[row.name] = 1
      if row.is_dir && row.state.tree_open
        let dir = s:next_dir_ctx(l, a:dir, src_path)
        let l = self._gather_changes(a:buf, dir, a:diff)
      endif
      continue
    endif

    call a:diff.moved_file(a:dir.path, row.name, {
      \   'abs_path': src_path,
      \   'name': node.name,
      \   'is_dir': node.is_dir,
      \ })
    if row.is_dir && row.state.tree_open
      let dir = s:next_dir_ctx(l, a:dir, src_path)
      let l = self._gather_changes(a:buf, dir, a:diff)
    endif
  endwhile

  call s:detect_deleted_files(a:dir, unchanged_files, a:diff)

  return l - 1
endfunction

function! s:detect_deleted_files(dir, unchanged_files, diff) abort
  let real_files = readdir(a:dir.path)
  for name in real_files
    if !has_key(a:unchanged_files, name)
      let is_dir = isdirectory(a:dir.path . '/' . name)
      call a:diff.deleted_file(a:dir.path, name, {'is_dir': is_dir})
    endif
  endfor
endfunction

function! s:next_dir_ctx(l, dir, path) abort
  let next_dir = {
    \   'lnum': a:l,
    \   'path': a:path,
    \   'depth': a:dir.depth + 1,
    \ }
  return next_dir
endfunction
