let s:filer = {
  \   '_dir': '',
  \   '_files': {},
  \   '_states': {},
  \   '_drafts': {},
  \ }

function! efiler#filer#new(buf, file_factory) abort
  let filer = deepcopy(s:filer)
  let filer._buf = a:buf
  let filer._file_factory = a:file_factory
  return filer
endfunction

function! s:filer.display(dir) abort
  let self._dir = a:dir
  let files = self._list_files_on_disk(self._dir)
  let states = self._buf.display_files(files)
  call self._merge_states(states)
endfunction

function! s:filer._merge_states(states) abort
  for state in a:states
    let self._states[state.file_id] = state
  endfor
endfunction

function! s:filer._state_from_line(lnum) abort
  let prop = self._buf.get_prop_at(a:lnum)
  if type(prop) == v:t_number
    return prop
  endif

  if !has_key(self._states, prop.id)
    throw '[efiler] prop exists but state not found' prop.id
  endif
  return self._states[prop.id]
endfunction

function! s:filer.toggle_tree() abort
  let cur_line = self._buf.cursor_line()

  let state = self._state_from_line(cur_line)
  let file = self._files[state.file_id]
  if !file.isdir
    return
  endif

  let modified_already = self._buf.modified()

  if state.tree.open
    call self._close_tree_rec(state, cur_line)
  else
    let files = self._list_files(file)
    let appended_states = self._buf.append_files(cur_line, state.depth + 1, files)
    call self._merge_states(appended_states)
    let state.tree.open = !state.tree.open
  endif

  if !modified_already
    call self._buf.save()
  endif
endfunction

function! s:filer._close_tree_rec(state, lnum) abort
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
      let self._states[file.id] = {'file_id': file.id, 'depth': depth, 'tree': {'open': 0}}
      call add(file_ids, file.id)
      continue
    endif

    let file = self._files[node.file_id]
    if file.dir != my_path
      break
    endif

    call add(file_ids, file.id)

    if file.isdir && node.tree.open
      call self._close_tree_rec(node, l)
    endif
  endwhile

  if modified
    let self._drafts[me.id] = {'file_ids': file_ids}
  endif

  if a:lnum + 1 < l
    call self._buf.delete_lines(a:lnum + 1, l - 1)
  endif
  let a:state.tree.open = !a:state.tree.open
endfunction

function! s:filer.go_up_dir() abort
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

function! s:filer.go_down_dir() abort
  let state = self._state_from_line(self._buf.cursor_line())
  let path = self._files[state.file_id].abs_path()[0:-2] " Strip the last slash.
  call self.display(path)
  call self._buf.put_cursor(1, 1)
endfunction

function! s:filer._list_files(file) abort
  if has_key(self._drafts, a:file.id)
    let files = []
    for id in self._drafts[a:file.id].file_ids
      call add(files, self._files[id])
    endfor
    return files
  endif
  return self._list_files_on_disk(a:file.abs_path())
endfunction

function! s:filer._list_files_on_disk(dir) abort
  let files = []
  for name in readdir(a:dir)
    let file = self._make_file(a:dir, name)
    call add(files, file)
  endfor
  return files
endfunction

function! s:filer._make_file(dir, name) abort
  let file = self._file_factory.new_file(a:dir, a:name)
  let self._files[file.id] = file
  return file
endfunction

function! s:filer._make_draft_file(dir, name, opt) abort
  let file = self._file_factory.new_draft_file(a:dir, a:name, a:opt)
  let self._files[file.id] = file
  return file
endfunction

