" Manage nodes globally.
" An association between a path and node id is immutable and never deleted.

let s:NodeStore = {}

function! viler#NodeStore#new() abort
  let store = deepcopy(s:NodeStore)
  let store._id = 0
  let store._nodes = {}
  let store._path2node = {}
  let store._displayed_nodes = {}
  return store
endfunction

function! s:NodeStore.try_get_node(id) abort
  return get(self._nodes, a:id, 0)
endfunction

function! s:NodeStore.get_node(id) abort
  if !has_key(self._nodes, a:id)
    throw '[viler] Unknown Node ID: ' . a:id
  endif
  return self._nodes[a:id]
endfunction

function! s:NodeStore.try_get_node_from_path(path) abort
  return get(self._path2node, a:path, 0)
endfunction

function! s:NodeStore.make_node(abs_path) abort
  let self._id += 1
  return self.get_or_make_node(self._id, a:abs_path)
endfunction

function! s:NodeStore.get_or_make_node(id, abs_path) abort
  if has_key(self._nodes, a:id)
    return self._nodes[a:id]
  endif
  let node = viler#Node#new(a:id, a:abs_path)
  let self._nodes[node.id] = node
  let self._path2node[a:abs_path] = node
  return node
endfunction

function! s:NodeStore.get_or_make_node_from_path(abs_path) abort
  if has_key(self._path2node, a:abs_path)
    return self._path2node[a:abs_path] 
  endif
  return self.make_node(a:abs_path)
endfunction

function! s:NodeStore.clear_displayed_nodes() abort
  let self._displayed_nodes = {}
endfunction

function! s:NodeStore.node_displayed(node_id, yes) abort
  if a:yes
    let self._displayed_nodes[a:node_id] = 1
  elseif has_key(self._displayed_nodes, a:node_id)
    call remove(self._displayed_nodes, a:node_id)
  endif
endfunction

function! s:NodeStore.should_be_displayed(node_id) abort
  return has_key(self._displayed_nodes, a:node_id)
endfunction
