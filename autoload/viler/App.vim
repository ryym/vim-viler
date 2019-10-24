let s:repo_root = expand('<sfile>:p:h:h:h')

let s:App = {}

function! viler#App#create(work_dir) abort
  let node_store = viler#NodeStore#new()

  return viler#App#new(
    \   a:work_dir,
    \   node_store,
    \ )
endfunction

function! viler#App#new(work_dir, node_store) abort
  let app = deepcopy(s:App)
  let app._filer_id = 0
  let app._filers = {}
  let app._work_dir = a:work_dir
  let app._node_store = a:node_store
  let app._commit_id = 0
  return app
endfunction

function! s:App.is_debug() abort
  return 1
endfunction

function! s:App.create_filer(dir) abort
  let self._filer_id += 1
  let temp_file = self._work_dir . '/filer' . self._filer_id . '.viler'
  let buffer = viler#Buffer#new()
  let bufnr = buffer.open(temp_file)

  let node_accessor = self._node_store.accessor_for(bufnr)

  let filer = viler#Filer#new(
    \   self._commit_id,
    \   buffer,
    \   node_accessor,
    \ )
  let self._filers[bufnr] = filer

  call filer.display(a:dir)
endfunction

function! s:App.open(bufnr, dir) abort
  if !has_key(self._filers, a:bufnr)
    throw '[viler] Unknown buffer' a:bufnr
  endif

  let filer = self._filers[a:bufnr]
  call filer.display(a:dir)
endfunction

function! s:App.has_filer_for(bufnr) abort
  return has_key(self._filers, a:bufnr)
endfunction

function! s:App.filer_for(bufnr) abort
  return get(self._filers, a:bufnr, 0)
endfunction

function! s:App.on_any_buf_save() abort
  let filers = values(self._filers)

  call self._apply_changes(filers)
  let self._commit_id += 1

  let current_bufnr = bufnr('%')
  for filer in filers
    call filer.set_commit_id(self._commit_id)
    let buf = filer.buffer()
    if buf.modified()
      execute 'silent keepalt buffer' buf.nr()
      silent noautocmd write
    endif
    call filer.refresh()
  endfor
  execute 'silent keepalt buffer' current_bufnr
endfunction

function! s:App._apply_changes(filers) abort
  let id_gen = viler#IdGen#new()

  let work_dir = $HOME . '/.viler/apply'
  if !isdirectory(work_dir)
    call mkdir(work_dir, "p")
  endif

  let reconciler = viler#Reconciler#new(id_gen, self._node_store, work_dir)
  call reconciler.reconcile(a:filers)
endfunction
