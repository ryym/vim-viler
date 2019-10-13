let s:Diff = {}

function! viler#applier#Diff#new(id_gen) abort
  let diff = deepcopy(s:Diff)

  let diff._dir_id = a:id_gen
  let diff.dirs = {}
  let diff.copies = {}
  let diff.deletions = {}
  let diff._copy_id = 0 " XXX: tmp
  let diff.deleted_paths = []

  let root = s:new_dir(a:id_gen.make_id(), -1, '')
  let diff.dirs[root.id] = root
  let diff.root_dir_id = root.id

  return diff
endfunction

function! s:Diff.register_dirs_from_path(path) abort
  let dir_names = split(a:path, '/')
  let dir = self.dirs[self.root_dir_id]
  let size = len(dir_names)
  let i = 0

  while i < size
    let dir_name = dir_names[i]
    " Skip already created directories.
    if has_key(dir.dirs, dir_name)
      let dir = self.dirs[dir.dirs[dir_name]]
      let i += 1
    else
      break
    endif
  endwhile

  " Create not registered directories.
  for dir_name in dir_names[i:]
    let child = self._new_dir(dir.id, dir_name)
    let dir.dirs[child.name] = child.id
    let dir = child
  endfor

  return dir
endfunction

function! s:Diff.get_or_make_dir(dir_id, name) abort
  let parent = self.dirs[a:dir_id]
  if has_key(parent.dirs, a:name)
    return self.dirs[parent.dirs[a:name]]
  endif
  let dir = self._new_dir(a:dir_id, a:name)
  let parent.dirs[dir.name] = dir.id
  return dir
endfunction

function! s:Diff._new_dir(parent_id, name) abort
  let id = self._dir_id.make_id()
  let dir = s:new_dir(id, a:parent_id, a:name)
  let self.dirs[id] = dir
  return dir
endfunction

function! s:Diff.new_file(dir_id, name, stat) abort
  let dir = self.dirs[a:dir_id]
  call add(dir.changes.add, {'name': a:name, 'is_dir': a:stat.is_dir})
endfunction

function! s:Diff.copied_file(dir_id, name, src) abort
  let path = a:src.abs_path
  let parent_path = fnamemodify(path, ':h')
  let src_parent = self.register_dirs_from_path(parent_path)

  let self._copy_id += 1
  let copy_entry = {
    \   'id': self._copy_id,
    \   'src': { 'id': src_parent.id, 'name': a:src.name },
    \   'dest': { 'id': a:dir_id, 'name': a:name }
    \ }
  let self.copies[self._copy_id] = copy_entry
  let self.dirs[a:dir_id].changes.copy_from[self._copy_id] = 1
endfunction

function! s:Diff.deleted_file(dir_id, name) abort
  let dir = self.dirs[a:dir_id]
  let dir.changes.delete[a:name] = 1
  let self.deletions[a:dir_id . '_' . a:name] = 1
endfunction

function! s:new_dir(id, parent_id, name) abort
  return {
    \   'id': a:id,
    \   'parent': a:parent_id,
    \   'name': a:name,
    \   'dirs': {},
    \   'changes': {'add': [], 'copy_from': {}, 'move_away': [], 'delete': {}},
    \ }
endfunction
