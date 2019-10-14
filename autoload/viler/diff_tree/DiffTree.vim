let s:DiffTree = {}

function! viler#diff_tree#DiffTree#new(id_gen) abort
  let diff = deepcopy(s:DiffTree)

  let diff._id_gen = a:id_gen
  let diff.nodes = {}
  let diff.copies = {}
  let diff.deletions = {}
  let diff._copy_id = 0 " XXX: tmp
  let diff.deleted_paths = []

  let root = s:make_node(a:id_gen.make_id(), -1, '', 1)
  let diff.nodes[root.id] = root
  let diff.root_dir_id = root.id

  return diff
endfunction

function! s:DiffTree.register_dirs_from_path(path) abort
  let dir_names = split(a:path, '/')
  let dir = self.nodes[self.root_dir_id]
  let size = len(dir_names)
  let i = 0

  while i < size
    let dir_name = dir_names[i]
    " Skip already created directories.
    if has_key(dir.children, dir_name)
      let dir = self.get_dir(dir.children[dir_name])
      let i += 1
    else
      break
    endif
  endwhile

  " Create not registered directories.
  for dir_name in dir_names[i:]
    let child = self.make_node(dir.id, dir_name, 1)
    let dir.children[child.name] = child.id
    let dir = child
  endfor

  return dir
endfunction

function! s:DiffTree.get_dir(id) abort
  let dir = self.nodes[a:id]
  if !dir.is_dir
    throw '[viler] ' . dir.name . ' is not a directory'
  endif
  return dir
endfunction

function! s:DiffTree.get_node(id) abort
  return self.nodes[a:id]
endfunction

" XXX: children に {name:id} で持つ必要はある？
" 単に id のリスト or {id:1} の方が情報重複せず良い？
function! s:DiffTree.get_or_make_node(parent_id, name, is_dir) abort
  let parent = self.get_dir(a:parent_id)
  if has_key(parent.children, a:name)
    return self.nodes[parent.children[a:name]]
  endif
  let dir = self.make_node(a:parent_id, a:name, a:is_dir)
  let parent.children[dir.name] = dir.id
  return dir
endfunction

function! s:DiffTree.make_node(parent_id, name, is_dir) abort
  let id = self._id_gen.make_id()
  let node = s:make_node(id, a:parent_id, a:name, a:is_dir)
  let self.nodes[id] = node
  return node
endfunction

function! s:DiffTree.new_file(parent_id, name, stat) abort
  let dir = self.get_dir(a:parent_id)
  " children に入れなくてもいい？
  let file = self.get_or_make_node(a:parent_id, a:name, a:stat.is_dir)
  call add(dir.changes.add, file.id)
endfunction

function! s:DiffTree.copied_file(parent_id, name, src) abort
  let path = a:src.abs_path
  let src_parent_path = fnamemodify(path, ':h')
  let src_parent_dir = self.register_dirs_from_path(src_parent_path)

  let src_node = self.get_or_make_node(src_parent_dir.id, a:src.name, a:src.is_dir)
  let dest_node = self.get_or_make_node(a:parent_id, a:name, a:src.is_dir)

  let self._copy_id += 1
  let copy_entry = {
    \   'id': self._copy_id,
    \   'src_id': src_node.id,
    \   'dest_id': dest_node.id,
    \   'is_move': 0,
    \   'done': 0,
    \ }
  let self.copies[self._copy_id] = copy_entry

  let dest_parent_dir = self.get_dir(a:parent_id)
  call add(dest_parent_dir.changes.copy_from, self._copy_id)
endfunction

function! s:DiffTree.deleted_file(parent_id, name, stat) abort
  let dir = self.get_dir(a:parent_id)
  let file = self.get_or_make_node(a:parent_id, a:name, a:stat.is_dir)
  let dir.changes.delete[file.id] = 1
  let self.deletions[file.id] = 1
endfunction

function! s:make_node(id, parent_id, name, is_dir) abort
  return {
    \   'id': a:id,
    \   'parent': a:parent_id,
    \   'name': a:name,
    \   'is_dir': a:is_dir,
    \   'children': {},
    \   'changes': {'add': [], 'copy_from': [], 'move_away': [], 'delete': {}},
    \ }
endfunction

