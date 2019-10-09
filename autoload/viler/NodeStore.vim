let s:NodeStore = {}

function! viler#NodeStore#new() abort
  let store = deepcopy(s:NodeStore)
  let store._ids = {}
  let store._node_groups = {}
  return store
endfunction

function! s:NodeStore.try_get_node(group_id, id) abort
  let group = self._node_groups[a:group_id]
  return get(group, a:id, 0)
endfunction

function! s:NodeStore.get_node(group_id, id) abort
  let group = self._node_groups[a:group_id]
  return group[a:id]
endfunction

function! s:NodeStore.remove_node(group_id, id) abort
  let group = self._node_groups[a:group_id]
  call remove(group, a:id)
endfunction

function! s:NodeStore.clear_group(group_id) abort
  let self._node_groups[a:group_id] = {}
endfunction

function! s:NodeStore.make_node(group_id, abs_path) abort
  let id = self._ids[a:group_id] + 1
  let self._ids[a:group_id] = id
  return self.get_or_make_node(a:group_id, id, a:abs_path)
endfunction

function! s:NodeStore.get_or_make_node(group_id, id, abs_path) abort
  let group = self._node_groups[a:group_id]
  if has_key(group, a:id)
    return self._nodes[a:id]
  endif
  let node = viler#Node#new(a:id, a:abs_path)
  let group[node.id] = node
  return node
endfunction

let s:Accessor = {}

function! s:NodeStore.accessor_for(group_id) abort
  let self._ids[a:group_id] = 0
  let self._node_groups[a:group_id] = {}

  let accessor = deepcopy(s:Accessor)
  let accessor._store = self
  let accessor._group_id = a:group_id
  return accessor
endfunction

function! s:Accessor.get(id) abort
  let node = self._store.try_get_node(self._group_id, a:id)
  if type(node) == v:t_number
    throw '[viler] Unknown Node ID' a:id
  endif
  return node
endfunction

function! s:Accessor.remove(id) abort
  call self._store.remove_node(self._group_id, a:id)
endfunction

function! s:Accessor.clear() abort
  call self._store.clear_group(self._group_id)
endfunction

function! s:Accessor.make(abs_path) abort
  return self._store.make_node(self._group_id, a:abs_path)
endfunction

function! s:Accessor.get_or_make(id, abs_path) abort
  return self._store.get_or_make_node(self._group_id, a:id, a:abs_path)
endfunction
