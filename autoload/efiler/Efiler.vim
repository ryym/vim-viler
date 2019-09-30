let s:repo_root = expand('<sfile>:p:h:h:h')

let s:Efiler = {
  \   '_filer_id': 0,
  \   '_filers': {},
  \ }

function! efiler#Efiler#create() abort
  let id_gen = efiler#IdGen#new()
  return efiler#Efiler#new(id_gen)
endfunction

function! efiler#Efiler#new(id_gen) abort
  let efiler = deepcopy(s:Efiler)
  let efiler._id_gen = a:id_gen
  return efiler
endfunction

function! s:Efiler.open_new(dir) abort
  let temp_file = tempname() . '.efiler'
  let buffer = efiler#Buffer#new()
  let bufnr = buffer.open(temp_file)

  let self._filer_id += 1
  let filer = efiler#Filer#new(self._filer_id, buffer, self._id_gen)
  let self._filers[bufnr] = filer

  call filer.display(a:dir)
endfunction

function! s:Efiler.filer_for(bufnr) abort
  return get(self._filers, a:bufnr, 0)
endfunction
