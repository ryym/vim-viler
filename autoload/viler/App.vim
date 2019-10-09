let s:repo_root = expand('<sfile>:p:h:h:h')

let s:App = {}

function! viler#App#create(work_dir) abort
  let id_gen = viler#IdGen#new()
  let diff_checker = viler#DiffChecker#new()
  let arbitrator = viler#Arbitrator#new()
  return viler#App#new(a:work_dir, id_gen, diff_checker, arbitrator)
endfunction

function! viler#App#new(work_dir, id_gen, diff_checker, arbitrator) abort
  let viler = deepcopy(s:App)
  let viler._filer_id = 0
  let viler._filers = {}
  let viler._work_dir = a:work_dir
  let viler._id_gen = a:id_gen
  let viler._diff_checker = a:diff_checker
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

  let node_store = viler#NodeStore#new(self._id_gen)

  let filer = viler#Filer#new(
    \   self._filer_id,
    \   buffer,
    \   node_store,
    \   self._diff_checker,
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
  let diffs = []
  for bufnr in keys(self._filers)
    let filer = self._filers[bufnr]
    let diff = filer.gather_changes()
    call add(diffs, diff)
  endfor

  " TODO: Consider changes of all filers.
  let ops = self._arbitrator.decide_operations(diffs[0])

  " TODO: Just do reconciliation without the confirmation.
  " Instead of that, store deleted files in somewhere to
  " allow users to restore them later if needed.
  " FIXME: We don't want to show 'Press ENTER to continue' after the confirmation.
  if len(ops.delete) > 0
    " Should show all files inside it if a non-empty directory will be deleted.
    let filenames = join(ops.delete, ', ')
    let answer = confirm('Are you sure to delete ' . filenames, "yes\nno")
    if answer != 1
      throw 'Cancelled to save'
    endif
  endif

  let reconciler_work_dir = self._work_dir . '/mv_tmp'
  if !isdirectory(reconciler_work_dir)
    call mkdir(reconciler_work_dir)
  endif

  let reconciler = viler#Reconciler#new(reconciler_work_dir)
  call reconciler.apply(ops)
endfunction
