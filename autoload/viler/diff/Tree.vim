let s:Tree = {}

function! viler#diff#Tree#new() abort
  let tree = deepcopy(s:Tree)
  let tree._node_id = 0
  let tree._nodes = {}

  let root = viler#diff#Node#new(0, -1, '', 1, 0)
  let tree._nodes[root.id] = root
  let tree._root_dir_id = 0

  return tree
endfunction

function! s:Tree.root_dir() abort
  return self._nodes[self._root_dir_id]
endfunction

function! s:Tree._new_id() abort
  let self._node_id += 1
  return self._node_id
endfunction

function! s:Tree.get_node(id) abort
  return self._nodes[a:id]
endfunction

function! s:Tree.get_dir(id) abort
  let dir = self.get_node(a:id)
  if !dir.is_dir
    throw '[viler] ' . dir.name . ' is not a directory'
  endif
  return dir
endfunction

function! s:Tree.get_or_make_node(parent_id, name, is_dir, will) abort
  let parent = self.get_dir(a:parent_id)
  let child = self.get_child(parent, a:name, a:will)
  if type(child) != v:t_number
    return child
  endif
  let dir = self.make_node(a:parent_id, a:name, a:is_dir, a:will)
  return dir
endfunction

function! s:Tree.get_child(parent, child_name, will) abort
  for child_id in keys(a:parent.children)
    let child = self.get_node(child_id)
    if child.name == a:child_name && child.will == a:will
      return child
    endif
  endfor
  return 0
endfunction

function! s:Tree.make_node(parent_id, name, is_dir, will) abort
  let id = self._new_id()
  let node = viler#diff#Node#new(id, a:parent_id, a:name, a:is_dir, a:will)
  let self._nodes[a:parent_id].children[node.id] = 1
  let self._nodes[id] = node
  return node
endfunction

function! s:Tree.register_dirs_from_path(path) abort
  let dir_names = split(a:path, '/')
  let dir = self.root_dir()
  let size = len(dir_names)
  let i = 0

  while i < size
    let dir_name = dir_names[i]

    " XXX: We assume that the duplicate path does not exist here (unless the tree is invalid).
    " -> swap でダメ。。。
    let child = 0
    for child_id in keys(dir.children)
      let c = self.get_node(child_id)
      if c.name == dir_name
        let child = c
        break
      endif
    endfor

    if type(child) == v:t_number
      break
    else
      let dir = child
      let i += 1
    endif
  endwhile

  " Create not registered directories.
  for dir_name in dir_names[i:]
    let dir = self.make_node(dir.id, dir_name, 1, g:viler#diff#Node#will.stay)
  endfor

  return dir
endfunction

function! s:Tree.path(node) abort
  let node = a:node
  let parts = [node.name]
  while 1
    let node = self.get_node(node.parent)
    call add(parts, node.name)
    if node.id == self._root_dir_id
      break
    endif
  endwhile
  return parts->reverse()->join('/')
endfunction

function! s:Tree.remove_node(node_id) abort
  if a:node_id == self._root_dir_id
    throw '[viler] Cannot remove root node'
  endif

  let node = self.get_node(a:node_id)
  let parent = self.get_node(node.parent)
  call remove(parent.children, node.id) 

  return node
endfunction

function! s:Tree.move_node(node_id, new_parent_id, new_name) abort
  let parent = self.get_dir(a:new_parent_id)
  let node = self.remove_node(a:node_id)
  let node.name = a:new_name
  let parent.children[node.id] = 1
  let node.parent = a:new_parent_id
endfunction
