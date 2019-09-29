let s:repo_root = expand('<sfile>:p:h:h:h')

let s:Efiler = {
  \   '_filers': {},
  \   '_buf_id': 0,
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
  let self._buf_id += 1
  let buffer = efiler#Buffer#new(self._buf_id)
  let bufnr = buffer.open(temp_file)

  let filer = efiler#Filer#new(buffer, self._id_gen)
  let self._filers[bufnr] = filer

  call filer.display(a:dir)
endfunction
