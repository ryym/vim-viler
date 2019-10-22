let s:Maker = {}

function! viler#diff#Maker#new(node_store) abort
  let maker = deepcopy(s:Maker)
  let maker._node_store = a:node_store
  return maker
endfunction

function! s:Maker.gather_changes(buf, diff) abort
  let dir_path = a:buf.current_dir().path
  let root = a:diff.register_dirs_from_path(dir_path)
  let dir = {
    \   'lnum': 1,
    \   'is_new': 0,
    \   'id': root.id,
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
      if row.name == ''
        continue
      endif
      call a:diff.new_file(a:dir.id, row.name, {'is_dir': row.is_dir})

      " TODO: Handle nested new directory.
      " Probably we need to determine the directory is open or not by
      " an indentation of the next line.
      continue
    endif

    let node = self._node_store.get_node(row.bufnr, row.node_id)
    let row_path = a:dir.path . '/' . row.name
    let src_path = node.abs_path()
    if has_key(a:dir, 'subroot')
      let src_path = substitute(src_path, a:dir.subroot.src, a:dir.subroot.dest, '')
    endif

    if src_path == row_path
      let unchanged_files[row.name] = 1
      if row.is_dir && row.state.tree_open
        let node = a:diff.get_or_make_node(
          \   a:dir.id,
          \   row.name,
          \   1,
          \   g:viler#diff#Node#will.stay,
          \ )
        let dir = s:next_dir_ctx(l, a:dir, node, row, a:diff)
        let l = self._gather_changes(a:buf, dir, a:diff)
      endif
      continue
    endif

    let node = a:diff.moved_file(a:dir.id, row.name, {
      \   'abs_path': src_path,
      \   'name': node.name,
      \   'is_dir': node.is_dir,
      \ })
    if row.is_dir && row.state.tree_open
      let dir = s:next_dir_ctx(l, a:dir, node, row, a:diff)
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
      let is_dir = isdirectory(path . '/' . name)
      call a:diff.deleted_file(a:dir.id, name, {'is_dir': is_dir})
    endif
  endfor
endfunction

function! s:next_dir_ctx(l, dir, node, row, diff) abort
  let next_dir = {
    \   'lnum': a:l,
    \   'is_new': a:row.is_new,
    \   'id': a:node.id,
    \   'path': a:dir.path . '/' . a:node.name,
    \   'depth': a:dir.depth + 1,
    \ }
  if has_key(a:dir, 'subroot')
    let next_dir.subroot = a:dir.subroot
  endif
  return next_dir
endfunction

