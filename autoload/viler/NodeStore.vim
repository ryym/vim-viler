let s:NodeStore = {}

function! viler#NodeStore#new(id_gen) abort
  let store = deepcopy(s:NodeStore)
  let store._nodes = {}
  let store._id_gen = a:id_gen
  return store
endfunction

function! s:NodeStore.get(id) abort
  if !has_key(self._nodes, a:id)
    throw '[viler] Unknown Node ID' a:id
  endif
  return self._nodes[a:id]
endfunction

function! s:NodeStore.remove(id) abort
  call remove(self._nodes, a:id)
endfunction

function! s:NodeStore.clear() abort
  let self._nodes = {}
endfunction

function! s:NodeStore.make(abs_path) abort
  let id = self._id_gen.make()
  return self.get_or_make(id, a:abs_path)
endfunction

function! s:NodeStore.get_or_make(id, abs_path) abort
  if has_key(self._nodes, a:id)
    return self._nodes[a:id]
  endif
  let node = viler#Node#new(a:id, a:abs_path)
  let self._nodes[node.id] = node
  return node
endfunction
