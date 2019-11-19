" FlistFs does:
" - convert Flist to an actual file tree.
" - convert an actual file tree to Flist.
let s:FlistFs = {}

function! viler#testutil#FlistFs#create() abort
  let fs = viler#lib#Fs#new()
  return viler#testutil#FlistFs#new(fs)
endfunction

function! viler#testutil#FlistFs#new(fs) abort
  let fs = deepcopy(s:FlistFs)
  let fs._fs = a:fs
  return fs
endfunction

function! s:FlistFs.flist_to_files(root_dir, flist) abort
  call self._flist_to_files(a:flist.iter(), {'depth': 0, 'dir': a:root_dir})
endfunction

function! s:FlistFs._flist_to_files(iter, ctx) abort
  while a:iter.has_next()
    if a:iter.peek().depth < a:ctx.depth
      return
    endif

    let row = a:iter.next()
    let path = viler#Path#join(a:ctx.dir, row.name)

    if row.is_dir
      call self._fs.make_dir(path)
      let ctx = {'depth': a:ctx.depth + 1, 'dir': path}
      call self._flist_to_files(a:iter, ctx)
      continue
    endif

    if has_key(row, 'content')
      call self._fs.make_file_with(path, [row.content])
    else
      call self._fs.make_file(path)
    endif
  endwhile
endfunction

function! s:FlistFs.files_to_flist(dir) abort
  let rows = []
  call self._files_to_flist(a:dir, rows, 0)
  return viler#testutil#Flist#from_rows(rows) 
endfunction

function! s:FlistFs._files_to_flist(dir, rows, depth) abort
  let children = readdir(a:dir)
  for name in children
    let path = viler#Path#join(a:dir, name)
    let is_dir = isdirectory(path)
    let row = {
      \   'name': name,
      \   'is_dir': is_dir,
      \   'depth': a:depth,
      \ }
    call add(a:rows, row)

    if is_dir
      call self._files_to_flist(path, a:rows, a:depth + 1)
    else
      let content = readfile(path)
      if len(content) > 0
        let row.content = content[0]
      endif
    endif
  endfor
endfunction
