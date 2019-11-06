let s:Walker = {}

function! viler#diff#Walker#new() abort
  let walker = deepcopy(s:Walker)
  return walker
endfunction

function! s:Walker.walk_tree(dir, tree_iter, handlers) abort
  call self._walk_tree(a:dir, a:tree_iter, a:handlers)
endfunction

function! s:Walker._walk_tree(dir, iter, ctx) abort
  let unchanged_files = {}

  while a:iter.has_next()
    if a:iter.peek().depth < a:dir.depth
      break
    endif

    let row = a:iter.next()
    if row.depth != a:dir.depth
      throw '[vfiler] Wierd indentation at line ' . a:iter.lnum() - 1 . ': ' . row.name
    endif

    if row.is_new
      if row.name != ''
        call a:ctx.on_new_file(a:dir, row)
      endif
      continue
    endif

    let node = a:iter.filetree.associated_node(row)
    let row_path = viler#Path#join(a:dir.path, row.name)
    let src_path = node.abs_path()

    if src_path == row_path
      let unchanged_files[row.name] = 1
      if row.is_dir && row.state.tree_open
        let dir = s:next_dir_ctx(a:dir, src_path)
        call self._walk_tree(dir, a:iter, a:ctx)
      endif
      continue
    endif

    call a:ctx.on_moved_file(a:dir, row, {'path': src_path, 'node': node})
    if row.is_dir && row.state.tree_open
      let dir = s:next_dir_ctx(a:dir, src_path)
      call self._walk_tree(dir, a:iter, a:ctx)
    endif
  endwhile

  let real_files = readdir(a:dir.path)
  for name in real_files
    if !has_key(unchanged_files, name)
      let is_dir = isdirectory(viler#Path#join(a:dir.path, name))
      call a:ctx.on_deleted_file(a:dir, {'name': name, 'is_dir': is_dir})
    endif
  endfor
endfunction

function! s:next_dir_ctx(dir, path) abort
  let next_dir = {
    \   'path': a:path,
    \   'depth': a:dir.depth + 1,
    \ }
  return next_dir
endfunction
