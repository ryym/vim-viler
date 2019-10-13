let s:IdGen = {}

function! viler#IdGen#new() abort
  let id_gen = deepcopy(s:IdGen)
  let id_gen._id = 0
  return id_gen
endfunction

function! s:IdGen.make_id() abort
  let self._id += 1
  return self._id
endfunction

function! s:IdGen.reset() abort
  let self._id = 0
endfunction
