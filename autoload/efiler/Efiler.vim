let s:repo_root = expand('<sfile>:p:h:h:h')

let s:Efiler = {
  \   '_filer_id': 0,
  \   '_filers': {},
  \ }

function! efiler#Efiler#create() abort
  let id_gen = efiler#IdGen#new()
  let diff_checker = efiler#DiffChecker#new()
  return efiler#Efiler#new(id_gen, diff_checker)
endfunction

function! efiler#Efiler#new(id_gen, diff_checker) abort
  let efiler = deepcopy(s:Efiler)
  let efiler._id_gen = a:id_gen
  let efiler._diff_checker = a:diff_checker
  return efiler
endfunction

function! s:Efiler.open_new(dir) abort
  let temp_file = tempname() . '.efiler'
  let buffer = efiler#Buffer#new()
  let bufnr = buffer.open(temp_file)

  let self._filer_id += 1
  let filer = efiler#Filer#new(
    \   self._filer_id,
    \   buffer,
    \   self._id_gen,
    \   self._diff_checker,
    \ )
  let self._filers[bufnr] = filer

  call filer.display(a:dir)
endfunction

function! s:Efiler.filer_for(bufnr) abort
  return get(self._filers, a:bufnr, 0)
endfunction

function! s:Efiler.apply_changes() abort
  let changeset = {
    \   'added': {},
    \   'copied': {},
    \   'deleted': {},
    \ }

  for bufnr in keys(self._filers)
    let filer = self._filers[bufnr]
    call filer.gather_changes(changeset)
    " TODO: Gather changes from all filers.
    break
  endfor

  echom string(changeset)
endfunction
