let s:DiffChecker = {}

function! viler#DiffChecker#new() abort
  let checker = deepcopy(s:DiffChecker)
  return checker
endfunction

function! s:new_diff() abort
  return {'added': [], 'copied': [], 'deleted': []}
endfunction

function! s:DiffChecker.gather_changes(buf, nodes) abort
  let dir = a:buf.current_dir()
  let diff = s:new_diff()
  call self._gather_changes(
    \   {
    \     'path': dir.path,
    \     'lnum': a:buf.lnum_first() - 1,
    \     'depth': 0,
    \   },
    \   a:buf,
    \   a:nodes,
    \   diff,
    \ )
  return diff
endfunction

function! s:DiffChecker._gather_changes(dir, buf, nodes, diff) abort
  let l = a:dir.lnum
  let last_lnum = a:buf.lnum_last()
  let unchanged_files = {}

  while l < last_lnum
    let l += 1

    " TODO: Handle cases that a user changes the indent of rows.
    let row = a:buf.node_row(l)
    if row.depth < a:dir.depth
      break
    endif

    let row_abs_path = a:dir.path . '/' . row.name

    if row.is_new
      call add(a:diff.added, row_abs_path)
      " TODO: Handle nested directories.
      continue
    endif

    let node = a:nodes[row.node_id]
    let node_abs_path = node.abs_path()

    " If the row's path differs from the original path,
    " the file was copied (or moved).
    if node_abs_path != row_abs_path
      " TODO: Consider the case a same file is copied (or moved) to multiple paths.
      call add(a:diff.copied, {
        \   'src_path': node_abs_path,
        \   'dest_path': row_abs_path,
        \ })
    else
      let unchanged_files[node.name] = 1
    endif

    " TODO: Consider the case that a user copies a whole directory tree to the other
    " and edit its content.
    if row.is_dir && row.state.tree_open
      let lnum = self._gather_changes(
        \   {
        \     'path': row_abs_path,
        \     'lnum': l,
        \     'depth': a:dir.depth + 1,
        \   },
        \   a:buf,
        \   a:nodes,
        \   a:diff,
        \ )
      let l = lnum - 1
    endif
  endwhile

  " Detect deleted files.
  let real_files = readdir(a:dir.path)
  for name in real_files
    if !has_key(unchanged_files, name)
      call add(a:diff.deleted, a:dir.path . '/' . name)
    endif
  endfor

  return l
endfunction
