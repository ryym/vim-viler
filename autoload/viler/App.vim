let s:repo_root = expand('<sfile>:p:h:h:h')

let s:App = {}

function! viler#App#create(work_dir) abort
  let node_store = viler#NodeStore#new()
  let diff_id_gen = viler#IdGen#new()
  let diff_maker = viler#diff_tree#Maker#new(node_store, diff_id_gen)
  let arbitrator = viler#Arbitrator#new()

  return viler#App#new(
    \   a:work_dir,
    \   node_store,
    \   diff_maker,
    \   diff_id_gen,
    \   arbitrator,
    \ )
endfunction

function! viler#App#new(work_dir, node_store, diff_maker, diff_id_gen, arbitrator) abort
  let viler = deepcopy(s:App)
  let viler._filer_id = 0
  let viler._filers = {}
  let viler._work_dir = a:work_dir
  let viler._node_store = a:node_store
  let viler._diff_maker = a:diff_maker
  let viler._diff_id_gen = a:diff_id_gen
  let viler._arbitrator = a:arbitrator
  return viler
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
    \   buffer,
    \   node_accessor,
    \   self._diff_maker,
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

function! s:App.apply_changes() abort
  call self._diff_id_gen.reset()
  let diffs = []
  for bufnr in keys(self._filers)
    let filer = self._filers[bufnr]
    let diff = filer.gather_changes()
    call add(diffs, diff)
  endfor

  " XXX: For debug.
  let g:_diff = diffs[0]

  " let work_dir = self._work_dir . '/work'
  let work_dir = '/Users/ryu/ghq/github.com/ryym/vim-viler/_work'
  if !isdirectory(work_dir)
    call mkdir(work_dir)
  endif

  let planner = viler#applier#Planner#new(self._diff_id_gen, work_dir)

  " TODO: Handle changes of all filers.
  let g:_plan = planner.make_plan(diffs[0])

  " TODO: Enable to restore deleted files.
  " TODO: Apply the plan.
  let fs = viler#applier#Fs#new()
  let reconciler = viler#applier#Reconciler#new(g:_plan, fs)
  call reconciler.apply_changes()
endfunction
