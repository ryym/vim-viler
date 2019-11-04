let s:Walker = {}

function! viler#diff#Walker#new() abort
  let walker = deepcopy(s:Walker)
  return walker
endfunction

function! s:Walker.walk_tree(dir, tree, handlers) abort
  if !has_key(a:dir, 'lnum')
    let a:dir.lnum = a:tree.lnum_first() - 1
  endif
  call self._walk_tree(a:dir, a:tree, a:handlers)
endfunction

function! s:Walker._walk_tree(dir, tree, ctx) abort
  let l = a:dir.lnum
  let last_lnum = a:tree.lnum_last()
  let unchanged_files = {}

  while l < last_lnum
    let l += 1

    let row = a:tree.row(l)
    if row.depth < a:dir.depth
      break
    endif

    if row.depth != a:dir.depth
      throw '[vfiler] Wierd indentation at line ' . row.lnum . ': ' . row.name
    endif

    if row.is_new
      if row.name != ''
        call a:ctx.on_new_file(a:dir, row)
      endif
      continue
    endif

    let node = a:tree.associated_node(row)
    let row_path = viler#Path#join(a:dir.path, row.name)
    let src_path = node.abs_path()

    if src_path == row_path
      let unchanged_files[row.name] = 1
      if row.is_dir && row.state.tree_open
        let dir = s:next_dir_ctx(l, a:dir, src_path)
        let l = self._walk_tree(dir, a:tree, a:ctx)
      endif
      continue
    endif

    call a:ctx.on_moved_file(a:dir, row, {'path': src_path, 'node': node})
    if row.is_dir && row.state.tree_open
      let dir = s:next_dir_ctx(l, a:dir, src_path)
      let l = self._walk_tree(dir, a:buf, a:ctx)
    endif
  endwhile

  let real_files = readdir(a:dir.path)
  for name in real_files
    if !has_key(unchanged_files, name)
      let is_dir = isdirectory(viler#Path#join(a:dir.path, name))
      call a:ctx.on_deleted_file(a:dir, {'name': name, 'is_dir': is_dir})
    endif
  endfor

  return l - 1
endfunction

function! s:next_dir_ctx(l, dir, path) abort
  let next_dir = {
    \   'lnum': a:l,
    \   'path': a:path,
    \   'depth': a:dir.depth + 1,
    \ }
  return next_dir
endfunction
