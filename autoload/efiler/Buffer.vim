let s:Buffer = {'_id': 0, '_nr': 0}

function! efiler#Buffer#new(id) abort
  let buffer = deepcopy(s:Buffer)
  let buffer._id = a:id
  return buffer
endfunction

function! s:Buffer.open(path) abort
  execute 'silent edit' a:path
  let self._nr = bufnr('%')
  return self._nr
endfunction

function! s:Buffer.nr() abort
  return self._nr
endfunction

function! s:Buffer.display_nodes(nodes) abort
  let first_line_to_remove = len(a:nodes) + 1
  let names = map(copy(a:nodes), {_, n -> n.name})
  call setbufline(self._nr, 1, names)
  call deletebufline(self._nr, first_line_to_remove, '$')

  noautocmd silent write
endfunction
