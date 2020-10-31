let s:NodeStore = {}

function! viler#NodeStore#new() abort
  let store = deepcopy(s:NodeStore)
  let store._ids = {}
  let store._groups = {}
  return store
endfunction

function! s:NodeStore.try_get_node(group_id, id) abort
  let group = self._groups[a:group_id]
  return get(group.nodes, a:id, 0)
endfunction

function! s:NodeStore.get_node(group_id, id) abort
  let group = self._groups[a:group_id]
  return group.nodes[a:id]
endfunction

function! s:NodeStore.try_get_node_from_path(group_id, path) abort
  let group = self._groups[a:group_id]
  return get(group.path2node, a:path, 0)
endfunction

function! s:NodeStore.remove_node(group_id, id) abort
  let group = self._groups[a:group_id]
  call remove(group.nodes, a:id)
endfunction

function! s:NodeStore.reset_group(group_id) abort
  let self._groups[a:group_id] = {'nodes': {}, 'path2node': {}}
endfunction

function! s:NodeStore.make_node(group_id, abs_path) abort
  let id = self._ids[a:group_id] + 1
  let self._ids[a:group_id] = id
  return self.get_or_make_node(a:group_id, id, a:abs_path)
endfunction

function! s:NodeStore.get_or_make_node(group_id, id, abs_path) abort
  let group = self._groups[a:group_id]
  if has_key(group.nodes, a:id)
    return self._nodes[a:id]
  endif
  let node = viler#Node#new(a:id, a:abs_path)
  let group.nodes[node.id] = node
  let group.path2node[a:abs_path] = node
  return node
endfunction

function! s:NodeStore.accessor_for(group_id) abort
  let self._ids[a:group_id] = 0
  call self.reset_group(a:group_id)
  return viler#NodeAccessor#new(self, a:group_id)
endfunction
