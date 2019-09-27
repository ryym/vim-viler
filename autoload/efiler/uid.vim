let s:uid = {'_id': 0, '_path_to_id': {}, '_draft_id': 0}

function! efiler#uid#new() abort
  let uid = deepcopy(s:uid)
  return uid
endfunction

function! s:uid.get(abs_path) abort
  if has_key(self._path_to_id, a:abs_path)
    return self._path_to_id[a:abs_path]
  endif
  let self._id += 1
  let self._path_to_id[a:abs_path] = self._id
  return self._id
endfunction

function! s:uid.draft_id() abort
  let self._draft_id -= 1
  return self._draft_id
endfunction
