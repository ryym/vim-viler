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

function! viler#App#reconciliation_work_dir() abort
  return $HOME . '/.viler/apply'
endfunction

function! s:App.create_filer(dir) abort
  let self._filer_id += 1
  let temp_file = self._work_dir . '/' . string(self._filer_id) . '.viler'
  execute 'silent edit' temp_file

  let buffer = viler#Buffer#new()
  let bufnr = bufnr('%')
  call buffer.bind(bufnr)

  let diff_checker = viler#diff#Checker#new(self._node_store)

  let filer = viler#Filer#new(
    \   self._commit_id,
    \   buffer,
    \   self._node_store,
    \   diff_checker,
    \ )
  let self._filers[bufnr] = filer

  call filer.display(a:dir, {})
  return filer
endfunction

function! s:App.open(bufnr, dir) abort
  if !has_key(self._filers, a:bufnr)
    throw '[viler] Unknown buffer' a:bufnr
  endif

  let filer = self._filers[a:bufnr]
  call filer.display(a:dir, {})
endfunction

function! s:App.has_filer_for(bufnr) abort
  return has_key(self._filers, a:bufnr)
endfunction

function! s:App.filer_for(bufnr) abort
  return get(self._filers, a:bufnr, 0)
endfunction


function! s:App._valid_filers() abort
  return filter(copy(self._filers), 'v:val.buffer().exists()')
endfunction

function! s:App.on_any_buf_save() abort
  let filers = self._valid_filers()
  let modified_filers = filter(copy(values(filers)), 'v:val.buffer().modified()')

  call self._apply_changes(modified_filers)
  let self._commit_id += 1

  let current_bufnr = bufnr('%')

  " Update all filers to synchronize latest commit id.
  for filer in values(filers)
    let buf = filer.buffer()
    " call g:t.log('before keepalt', buf.nr())
    execute 'silent keepalt buffer!' buf.nr()
    silent noautocmd update
    call filer.commit(self._commit_id)
  endfor
  execute 'silent keepalt buffer' current_bufnr
endfunction

function! s:App._apply_changes(filers) abort
  let id_gen = viler#IdGen#new()

  let work_dir = viler#App#reconciliation_work_dir()
  if !isdirectory(work_dir)
    call mkdir(work_dir, "p")
  endif

  let drafts = map(
    \   copy(a:filers),
    \   {_, f -> viler#Draft#from_buf(f.buffer(), self._node_store)},
    \ )

  let reconciler = viler#Reconciler#new(id_gen, work_dir)
  call reconciler.reconcile(self._commit_id, drafts)
endfunction
