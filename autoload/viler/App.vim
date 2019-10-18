let s:repo_root = expand('<sfile>:p:h:h:h')

let s:App = {}

function! viler#App#create(work_dir) abort
  let node_store = viler#NodeStore#new()
  let diff_maker = viler#diff#Maker#new(node_store)

  return viler#App#new(
    \   a:work_dir,
    \   node_store,
    \   diff_maker,
    \ )
endfunction

function! viler#App#new(work_dir, node_store, diff_maker) abort
  let viler = deepcopy(s:App)
  let viler._filer_id = 0
  let viler._filers = {}
  let viler._work_dir = a:work_dir
  let viler._node_store = a:node_store
  let viler._diff_maker = a:diff_maker
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
  let tree = viler#diff#Tree#new()
  let id_gen = viler#IdGen#new()

  let diffs = []
  for bufnr in keys(self._filers)
    let filer = self._filers[bufnr]
    let diff = viler#diff#Diff#new(tree, id_gen)
    call filer.gather_changes(diff)
    call add(diffs, diff)
  endfor

  let validator = viler#diff#Validator#new(tree)
  let unifier = viler#diff#Unifier#new(tree, id_gen, validator)
  let result = unifier.unify_diffs(diffs)

  if has_key(result, 'error')
    throw '[viler] ' . string(result.error)
  endif
  let final_diff = result.ok

  " XXX: For debug.
  let g:_tree = tree._nodes
  let g:_diff = {'dirops': final_diff.dirops, 'copies': final_diff.copies}

  let work_dir = {
    \   'path': '/Users/ryu/ghq/github.com/ryym/vim-viler/_work',
    \   'path_from_root': 'Users/ryu/ghq/github.com/ryym/vim-viler/_work',
    \ }

  let fs = viler#Fs#new()
  let applier = viler#diff#Applier#new(tree, final_diff, fs, work_dir)
  call applier.apply_changes()
endfunction
