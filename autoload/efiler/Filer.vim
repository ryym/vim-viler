let s:Filer = {
  \   '_dir': '',
  \   '_files': {},
  \   '_states': {},
  \   '_drafts': {},
  \   '_last_selection': [],
  \ }

function! efiler#Filer#new(buf, file_factory) abort
  let filer = deepcopy(s:Filer)
  let filer._buf = a:buf
  let filer._file_factory = a:file_factory
  return filer
endfunction

function! s:Filer.display(dir) abort
  let self._dir = a:dir
  let dir_file = self._make_file(fnamemodify(a:dir, ':h'), fnamemodify(a:dir, ':t'))

  let files = self._list_files(dir_file)
  call self._display_files(files)
endfunction

function! s:Filer._display_files(files) abort
  call self._buf.display_files(a:files)
  call self._append_states(a:files, 0)
endfunction

function! s:Filer._append_files(lnum, depth, files) abort
  call self._buf.append_files(a:lnum, a:depth, a:files)
  call self._append_states(a:files, a:depth)
endfunction

function! s:Filer._append_states(files, depth) abort
  for file in a:files
    let self._states[file.id] = {
      \   'file_id': file.id,
      \   'depth': a:depth,
      \   'tree_open': 0,
      \ }
  endfor
endfunction

function! s:Filer._state_from_line(lnum) abort
  let prop = self._buf.get_prop_at(a:lnum)
  if type(prop) == v:t_number
    return prop
  endif

  if !has_key(self._states, prop.id)
    throw '[efiler] prop exists but state not found' prop.id
  endif
  return self._states[prop.id]
endfunction

function! s:Filer.toggle_tree() abort
  let cur_line = self._buf.cursor_line()
  call prop_add(cur_line, 1, {'type': 'hoge', 'bufnr': self._buf.nr()})

  let line = substitute(getline('.'), '\v^\d+', '', '')
  call setline('.', '456' . line)
  call append(cur_line, ['hoge'])

  " let cur_line = self._buf.cursor_line()

  " let state = self._state_from_line(cur_line)
  " let file = self._files[state.file_id]
  " if !file.isdir
  "   return
  " endif

  " let modified_already = self._buf.modified()

  " if state.tree_open
  "   call self._close_tree_rec(state, cur_line)
  " else
  "   let files = self._list_files(file)
  "   call self._append_files(cur_line, state.depth + 1, files)
  "   let state.tree_open = !state.tree_open
  " endif

  " if !modified_already
  "   call self._buf.save()
  " endif
endfunction

function! s:Filer._close_tree_rec(state, lnum) abort
  let me = self._files[a:state.file_id]
  let my_path = me.abs_path()
  
  let modified = 0
  let file_ids = []
  let l = a:lnum
  let last_lnum = self._buf.last_lnum()
  while l < last_lnum
    let l += 1
    let node = self._state_from_line(l)

    " New file (TODO: Maybe it is in the parent directory).
    if type(node) == v:t_number
      let modified = 1
      let depth = a:state.depth + 1
      let name = self._buf.name_on_line(l, depth)
      let file = self._make_draft_file(my_path, name, {})
      call self._append_states([file], depth)
      call add(file_ids, file.id)
      continue
    endif

    " copied or moved or existing
    " copy or move の場合は既に draft_id になってるはず。
    " ただし rename はそうなってない。 name != file.name で判定できる。

    let file = self._files[node.file_id]
    if file.dir != my_path
      break
    endif

    call add(file_ids, file.id)

    if file.isdir && node.tree_open
      call self._close_tree_rec(node, l)
    endif
  endwhile

  if modified
    let self._drafts[me.id] = {'file_ids': file_ids}
  endif

  if a:lnum + 1 < l
    call self._buf.delete_lines(a:lnum + 1, l - 1)
  endif
  let a:state.tree_open = !a:state.tree_open
endfunction

function! s:Filer.go_up_dir() abort
  let parent_dir = fnamemodify(self._dir, ':h')
  if parent_dir == self._dir
    return
  endif

  let cur_path = self._dir . '/'
  call self.display(parent_dir)

  " Put a cursor at the directory we came from.
  let l = 0
  while l < line('$')
    let l += 1
    let state = self._state_from_line(l)
    if self._files[state.file_id].abs_path() == cur_path
      call self._buf.put_cursor(l, 1)
      break
    endif
  endwhile
endfunction

function! s:Filer.go_down_dir() abort
  let state = self._state_from_line(self._buf.cursor_line())
  let file = self._files[state.file_id]
  if !file.isdir
    return
  endif

  let path = file.abs_path()[0:-2] " Strip the last slash.
  call self.display(path)
  call self._buf.put_cursor(1, 1)
endfunction

function! s:Filer.delete_for_move() abort
  let range = self._buf.selection_range()
  if range.first == 0
    return
  endif

  let files = []
  let l = range.first - 1
  while l < range.last
    let l += 1
    let state = self._state_from_line(l)
    call add(files, self._files[state.file_id])
  endwhile

  let self._last_selection = files
  call self._buf.delete_lines(range.first, range.last)
endfunction

function! s:Filer.paste_selected() abort
  if len(self._last_selection) == 0
    return
  endif

  " TODO: It may be an added file which has not a state.
  let cur_lnum = self._buf.cursor_line()
  let cur_state = self._state_from_line(cur_lnum)
  let cur_file = self._files[cur_state.file_id]

  let draft_files = []
  for original in self._last_selection
    let file = self._make_draft_file(cur_file.dir, original.name, {
      \   'original_file_id': original.id,
      \ })
    call add(draft_files, file)
  endfor

  call self._append_files(cur_lnum, cur_state.depth, draft_files)
endfunction

function! s:Filer._list_files(file) abort
  if has_key(self._drafts, a:file.id)
    let files = []
    for id in self._drafts[a:file.id].file_ids
      call add(files, self._files[id])
    endfor
    return files
  endif

  " if a:file.isdraft && a:file.original_file_id
  "   let orig = self._files[a:file.original_file_id]
  "   return self._list_files(orig)
  " endif

  return self._list_files_on_disk(a:file.abs_path())
endfunction

function! s:Filer._list_files_on_disk(dir) abort
  let files = []
  for name in readdir(a:dir)
    let file = self._make_file(a:dir, name)
    call add(files, file)
  endfor
  return sort(files, function('s:sort_files_by_type_and_name'))
endfunction

function! s:Filer._make_file(dir, name) abort
  let file = self._file_factory.new_file(a:dir, a:name)
  let self._files[file.id] = file
  return file
endfunction

function! s:Filer._make_draft_file(dir, name, opt) abort
  let opt = copy(a:opt)
  if has_key(opt, 'original_file_id')
    let orig_id = opt.original_file_id
    while 1
      let orig = self._files[orig_id]
      if orig.isdraft && orig.original_file_id
        let orig_id = orig.original_file_id
      else
        break
      endif
    endwhile
    let opt.original_file_id = orig_id
  endif

  let file = self._file_factory.new_draft_file(a:dir, a:name, opt)
  let self._files[file.id] = file
  return file
endfunction

function! s:sort_files_by_type_and_name(a, b) abort
  if a:a.isdir != a:b.isdir
    return a:b.isdir - a:a.isdir
  endif
  if a:a.name == a:b.name
    return 0
  endif
  return a:a.name < a:b.name ? -1 : 1
endfunction
