let s:repo_root = expand('<sfile>:p:h:h:h')

let s:Efiler = {'_filers': {}}

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
  " TODO: Use temporary file.
  let sample_file = s:repo_root . '/sample.efiler'
  if !filereadable(sample_file)
    call writefile([], sample_file)
  endif
  execute 'silent edit' sample_file
  call deletebufline('%', 1, '$')
  noautocmd silent write

  let bufnr = bufnr('%')
  let buffer = efiler#Buffer#new(bufnr)
  let filer = efiler#Filer#new(buffer, self._id_gen)
  let self._filers[bufnr] = filer

  call filer.display(a:dir)
endfunction
