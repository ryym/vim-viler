let s:IdGen = {'_id': 0}

function! efiler#IdGen#new() abort
  let id_gen = deepcopy(s:IdGen)
  return id_gen
endfunction

function! s:IdGen.make() abort
  let self._id += 1
  return self._id
endfunction
