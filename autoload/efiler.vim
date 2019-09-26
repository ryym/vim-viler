let s:repo_root = expand('<sfile>:p:h:h')

function! efiler#enable() abort
  augroup efiler
    autocmd!

    autocmd FileType efiler call s:setup_buffer()
    autocmd BufNewFile,BufRead *.efiler setfiletype efiler
  augroup END

  command! Efiler call efiler#open()
endfunction

function! efiler#open()
  if !filereadable(s:repo_root . '/sample.efiler')
    call writefile([], s:repo_root . '/sample.efiler')
  endif
  execute 'silent edit' s:repo_root . '/sample.efiler'
endfunction

let s:states = {}

" XXX: For debug.
let g:_efs = s:states

function s:setup_buffer() abort
  if getbufvar('%', 'setup_done', 0)
    return
  endif
  let b:setup_done = 1

  Map n (buffer silent nowait) f ::call efiler#_toggle_tree()

  let files = s:list_files(getcwd())

  let first_line_to_remove = len(files) + 1
  let cur_buf = bufnr('%')

  call prop_type_add('file', {'bufnr': cur_buf})

  let filenames = map(copy(files), {_,f -> f.name})
  call setbufline(cur_buf, 1, filenames)
  call deletebufline(cur_buf, first_line_to_remove, '$')

  call s:register_props(files, cur_buf, 1, 0)

endfunction

function! s:list_files(dir) abort
  let files = []
  for abs_path in globpath(a:dir, '*', 0, 1)
    let file = s:make_file(abs_path)
    call add(files, file)
  endfor
  return files
endfunction

let s:_id = 0
function! s:uniq_id() abort
  let s:_id += 1
  return s:_id
endfunction

function! s:register_props(files, buf, start_line, depth) abort
  let i = 0
  while i < len(a:files)
    let file = a:files[i]
    let id = s:uniq_id()
    call prop_add(
      \   a:start_line + i, 1,
      \   {'type': 'file', 'bufnr': a:buf, 'id': id},
      \ )
    let s:states[id] = {
      \   'file': file,
      \   'depth': a:depth,
      \   'tree': {'open': 0},
      \ }

    let i += 1
  endwhile
endfunction

function! s:make_file(absolute_path) abort
  let dir = fnamemodify(a:absolute_path, ':h')
  if dir != '/'
    let dir .= '/'
  endif
  let name = fnamemodify(a:absolute_path, ':t')
  let isdir = isdirectory(a:absolute_path)
  if isdir
    let name .= '/'
  endif

  let file = { 'dir': dir, 'name': name, 'isdir': isdir }

  function! file.abs_path() abort
    return self.dir . self.name
  endfunction

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

  if state.tree.open
    call s:close_tree_rec(state, cur_buf, cur_line)
  else
    let files = s:list_files(state.file.abs_path())
    let indent = s:make_indent(state.depth + 1)
    let filenames = map(copy(files), {_, f-> indent . f.name})
    call append(cur_line, filenames)
    call s:register_props(files, cur_buf, cur_line + 1, state.depth + 1)
    let state.tree.open = !state.tree.open
  endif

  noautocmd silent write
endfunction

function! s:close_tree_rec(state, buf, line) abort
  let me = a:state.file.abs_path()
  let l = a:line + 1
  while l <= line('$')
    let node = s:get_state(l)
    if node.file.dir != me
      break
    endif

    if node.file.isdir && node.tree.open
      call s:close_tree_rec(node, a:buf, l)
    endif
    let l += 1
  endwhile
  if a:line + 1 < l
    call deletebufline(a:buf, a:line + 1, l - 1)
  endif
  let a:state.tree.open = !a:state.tree.open
endfunction
