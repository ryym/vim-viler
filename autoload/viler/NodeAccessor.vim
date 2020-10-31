let s:NodeAccessor = {}

function! viler#NodeAccessor#new(store, group_id) abort
  let accessor = deepcopy(s:NodeAccessor)
  let accessor._store = a:store
  let accessor._group_id = a:group_id
  return accessor
endfunction

function! s:NodeAccessor.get(id) abort
  let node = self._store.try_get_node(self._group_id, a:id)
  if type(node) is# v:t_number
    throw '[viler] Unknown Node ID: ' . a:id
  endif
  return node
endfunction

function! s:NodeAccessor.remove(id) abort
  call self._store.remove_node(self._group_id, a:id)
endfunction

function! s:NodeAccessor.clear() abort
  call self._store.reset_group(self._group_id)
endfunction

function! s:NodeAccessor.make(abs_path) abort
  return self._store.make_node(self._group_id, a:abs_path)
endfunction

function! s:NodeAccessor.get_or_make(id, abs_path) abort
  return self._store.get_or_make_node(self._group_id, a:id, a:abs_path)
endfunction
