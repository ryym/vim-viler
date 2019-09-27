let s:repo_root = expand('<sfile>:p:h:h')

function! efiler#enable() abort
  augroup efiler
    autocmd!

    autocmd BufNewFile,BufRead *.efiler setfiletype efiler
  augroup END

  command! Efiler call efiler#open()
endfunction

function! efiler#open()
  if !filereadable(s:repo_root . '/sample.efiler')
    call writefile([], s:repo_root . '/sample.efiler')
  endif

  execute 'silent edit' s:repo_root . '/sample.efiler'

  let cur_buf = bufnr('%')
  call s:setup_buffer(cur_buf)

  let s:cwd = getcwd()
  let files = s:list_files_on_disk(s:cwd)
  call s:display_files(cur_buf, files)
endfunction

let s:cwd = ''
let s:states = {}
let s:drafts = {}

" XXX: For debug.
let g:_efs = s:states
let g:_efd = s:drafts

function s:setup_buffer(buf) abort
  Map n (buffer silent nowait) f ::call efiler#_toggle_tree()
  Map n (buffer silent nowait) < ::call efiler#_go_up_dir()
  Map n (buffer silent nowait) > ::call efiler#_go_down_dir()

  call prop_type_add('file', {'bufnr': a:buf})
endfunction

function! s:display_files(buf, files) abort
  let first_line_to_remove = len(a:files) + 1
  let modified_already = &modified

  let filenames = map(copy(a:files), {_,f -> f.name})
  call setbufline(a:buf, 1, filenames)
  call deletebufline(a:buf, first_line_to_remove, '$')

  call s:register_props(a:files, a:buf, 1, 0)

  if !modified_already
    noautocmd silent write
  endif
endfunction

function! s:list_files(file) abort
  if has_key(s:drafts, a:file.id)
    let files = []
    for id in s:drafts[a:file.id].file_ids
      call add(files, s:states[id].file)
    endfor
    return files
  endif

  return s:list_files_on_disk(a:file.abs_path())
endfunction

function! s:list_files_on_disk(dir) abort
  let files = []
  for name in readdir(a:dir)
    let file = s:make_file(a:dir, name)
    call add(files, file)
  endfor
  return files
endfunction

let s:uid = {'_id': 0, '_path_to_id': {}, '_draft_id': 0}

function! s:uid.get(abs_path) abort
  if has_key(self._path_to_id, a:abs_path)
    return self._path_to_id[a:abs_path]
  endif
  let self._id += 1
  let self._path_to_id[a:abs_path] = self._id
  return self._id
endfunction

function! s:uid.draft_id() abort
  let self._draft_id -= 1
  return self._draft_id
endfunction

function! s:register_props(files, buf, start_line, depth) abort
  let i = 0
  while i < len(a:files)
    let file = a:files[i]
    call prop_add(
      \   a:start_line + i, 1,
      \   {'type': 'file', 'bufnr': a:buf, 'id': file.id},
      \ )
    let s:states[file.id] = {
      \   'file': file,
      \   'depth': a:depth,
      \   'tree': {'open': 0},
      \ }

    let i += 1
  endwhile
endfunction

function! s:make_file(dir, name) abort
  let dir = a:dir[len(a:dir) - 1] == '/' ? a:dir : a:dir . '/'
  let abs_path = dir . a:name
  let id = s:uid.get(abs_path)
  let isdir = isdirectory(abs_path)
  let name = isdir ? a:name . '/' : a:name

  let file = { 'id': id, 'dir': dir, 'name': name, 'isdir': isdir }

  function! file.abs_path() abort
    return self.dir . self.name
  endfunction

  return file
endfunction

function! s:make_draft_file(dir, name, opt) abort
  let dir = a:dir[len(a:dir) - 1] == '/' ? a:dir : a:dir . '/'
  let id = s:uid.draft_id()
  let isdir = a:name[len(a:name) - 1] == '/'

  let file = {
    \   'isdraft': 1,
    \   'id': id,
    \   'dir': dir,
    \   'name': a:name,
    \   'isdir': isdir,
    \ }

  return file
endfunction

function! s:make_indent(level) abort
  let s = ''
  let i = 0
  while i < a:level
    let s .= '  '
    let i += 1
  endwhile
  return s
endfunction

function! s:get_state(line) abort
  let props = prop_list(a:line)
  if len(props) == 0
    return 0
  endif

  let prop = props[0]
  if !has_key(s:states, prop.id)
    throw '[efiler] prop exists but state not found' prop.id
  endif
  return s:states[prop.id]
endfunction

function! efiler#_toggle_tree() abort
  let cur_buf = bufnr('%')
  let cur_line = line('.')

  let state = s:get_state(cur_line)

  if !state.file.isdir
    return
  endif

  let modified_already = &modified

  if state.tree.open
    call s:close_tree_rec(state, cur_buf, cur_line)
  else
    let files = s:list_files(state.file)
    let indent = s:make_indent(state.depth + 1)
    let filenames = map(copy(files), {_, f-> indent . f.name})
    call append(cur_line, filenames)
    call s:register_props(files, cur_buf, cur_line + 1, state.depth + 1)
    let state.tree.open = !state.tree.open
  endif

  if !modified_already
    noautocmd silent write
  endif
endfunction

function! s:close_tree_rec(state, buf, line) abort
  let me = a:state.file
  let my_path = me.abs_path()

  let modified = 0
  let file_ids = []
  let l = a:line + 1
  while l <= line('$')
    let node = s:get_state(l)

    " New file (TODO: Maybe it is in the parent directory).
    if type(node) == v:t_number
      let modified = 1
      let depth = a:state.depth + 1
      let name = s:get_name_on_buf(l, depth)
      let file = s:make_draft_file(my_path, name, {})
      let s:states[file.id] = {'file': file, 'depth': depth, 'tree': {'open': 0}}
      call add(file_ids, file.id)
      let l += 1
      continue
    endif

    if node.file.dir != my_path
      break
    endif

    call add(file_ids, node.file.id)

    if node.file.isdir && node.tree.open
      call s:close_tree_rec(node, a:buf, l)
    endif
    let l += 1
  endwhile

  if modified
    let s:drafts[me.id] = {'file_ids': file_ids}
  endif

  if a:line + 1 < l
    call deletebufline(a:buf, a:line + 1, l - 1)
  endif
  let a:state.tree.open = !a:state.tree.open
endfunction

function s:get_name_on_buf(lnum, depth) abort
  let line = getline(a:lnum)
  return line[a:depth * 2:]
endfunction

function! efiler#_go_up_dir() abort
  let cur_path = s:cwd . '/'
  let cwd = fnamemodify(s:cwd, ':h')
  if cwd == s:cwd
    return
  endif
  call s:change_dir(cwd)

  " Put a cursor at the directory we came from.
  let l = 1
  while l <= line('$')
    let state = s:get_state(l)
    if state.file.abs_path() == cur_path
      call cursor(l, 1)
      break
    endif
    let l += 1
  endwhile
endfunction

function! efiler#_go_down_dir() abort
  let state = s:get_state(line('.'))
  let path = state.file.abs_path()[0:-2] " Strip the last slash.
  call s:change_dir(path)
  call cursor(1, 1)
endfunction

function! s:change_dir(path) abort
  let s:cwd = a:path
 " TODO: Use s:list_files instead
  let files = s:list_files_on_disk(s:cwd)
  call s:display_files(bufnr('%'), files)
endfunction
