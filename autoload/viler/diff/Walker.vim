let s:Walker = {}

function! viler#diff#Walker#new() abort
  let walker = deepcopy(s:Walker)
  return walker
endfunction

function! s:Walker.walk_tree(dir, tree_iter, ctx) abort
  call self._walk_tree(a:dir, a:tree_iter, a:ctx)
endfunction

function! s:Walker._walk_tree(dir, iter, ctx) abort
  let unchanged_files = {}

  while a:iter.has_next()
    let row = a:iter.peek()

    if row.name is# ''
      call a:ctx.on_empty_line(a:dir, row)
      call a:iter.next()
      continue
    endif

    if row.depth < a:dir.depth
      break
    endif

    call a:iter.next()

    if row.depth isnot# a:dir.depth
      throw '[vfiler] Unexpected indentation at line ' . string(a:iter.lnum() - 1) . ': ' . row.name
    endif

    if row.is_new
      call a:ctx.on_new_file(a:dir, row)
      if row.is_dir
        let dir = s:next_dir_info(a:dir, viler#Path#join(a:dir.path, row.name))
        call self._walk_tree(dir, a:iter, a:ctx)
      endif
      continue
    endif

    if row.commit_id isnot# a:ctx.commit_id
      throw '[viler] Outdated row: ' . row.name . '. You cannot copy/paste rows over saving'
    endif

    let node = a:iter.filetree.associated_node(row)
    let row_path = viler#Path#join(a:dir.path, row.name)
    let src_path = node.abs_path()

    if src_path is# row_path
      if node.is_dir != row.is_dir
        throw '[viler] You cannot change file to directory or vice versa.'
      endif
      let unchanged_files[row.name] = 1
      if row.is_dir && row.state.tree_open
        let dir = s:next_dir_info(a:dir, src_path)
        call self._walk_tree(dir, a:iter, a:ctx)
      endif
      continue
    endif

    call a:ctx.on_moved_file(a:dir, row, {'path': src_path, 'node': node})
    if row.is_dir && row.state.tree_open
      let dir = s:next_dir_info(a:dir, src_path)
      call self._walk_tree(dir, a:iter, a:ctx)
    endif
  endwhile

  if isdirectory(a:dir.path)
    let real_files = viler#lib#Fs#readdir(a:dir.path)
    for name in real_files
      if !has_key(unchanged_files, name)
        " If a file is added in this directory outside of Viler, it must be preserved.
        " That's why we check the path has a corresponding Node. If not, the file is
        " added outside so we ignore it instead of marking it as deleted.
        let path = viler#Path#join(a:dir.path, name)
        if a:iter.filetree.has_node_for(path)
          call a:ctx.on_deleted_file(a:dir, {'name': name, 'is_dir': isdirectory(path)})
        endif
      endif
    endfor
  endif
endfunction

function! s:next_dir_info(dir, path) abort
  let next_dir = {
    \   'path': a:path,
    \   'depth': a:dir.depth + 1,
    \ }
  return next_dir
endfunction
