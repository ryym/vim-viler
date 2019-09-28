let s:Uid = {'_id': 0, '_path_to_id': {}, '_draft_id': 0}

function! efiler#Uid#new() abort
  let uid = deepcopy(s:Uid)
  return uid
endfunction

function! s:Uid.get(abs_path) abort
  if has_key(self._path_to_id, a:abs_path)
    return self._path_to_id[a:abs_path]
  endif
  let self._id += 1
  let self._path_to_id[a:abs_path] = self._id
  return self._id
endfunction

function! s:Uid.draft_id() abort
  let self._draft_id -= 1
  return self._draft_id
endfunction
