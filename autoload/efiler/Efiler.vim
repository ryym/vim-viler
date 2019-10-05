let s:repo_root = expand('<sfile>:p:h:h:h')

let s:Efiler = {
  \   '_filer_id': 0,
  \   '_filers': {},
  \ }

function! efiler#Efiler#create(work_dir) abort
  let id_gen = efiler#IdGen#new()
  let diff_checker = efiler#DiffChecker#new()
  let arbitrator = efiler#Arbitrator#new()
  return efiler#Efiler#new(a:work_dir, id_gen, diff_checker, arbitrator)
endfunction

function! efiler#Efiler#new(work_dir, id_gen, diff_checker, arbitrator) abort
  let efiler = deepcopy(s:Efiler)
  let efiler._work_dir = a:work_dir
  let efiler._id_gen = a:id_gen
  let efiler._diff_checker = a:diff_checker
  let efiler._arbitrator = a:arbitrator
  return efiler
endfunction

function! s:Efiler.create_filer(dir) abort
  let self._filer_id += 1

  let temp_file = self._work_dir . '/filer' . self._filer_id . '.efiler'
  let buffer = efiler#Buffer#new()
  let bufnr = buffer.open(temp_file)

  let filer = efiler#Filer#new(
    \   self._filer_id,
    \   buffer,
    \   self._id_gen,
    \   self._diff_checker,
    \ )
  let self._filers[bufnr] = filer

  call filer.display(a:dir)
endfunction

function! s:Efiler.open(bufnr, dir) abort
  if !has_key(self._filers, a:bufnr)
    throw '[efiler] Unknown buffer' a:bufnr
  endif

  let filer = self._filers[a:bufnr]
  call filer.display(a:dir)
endfunction

function! s:Efiler.has_filer_for(bufnr) abort
  return has_key(self._filers, a:bufnr)
endfunction

function! s:Efiler.filer_for(bufnr) abort
  return get(self._filers, a:bufnr, 0)
endfunction

function! s:Efiler.apply_changes() abort
  let diffs = []
  for bufnr in keys(self._filers)
    let filer = self._filers[bufnr]
    let diff = filer.gather_changes()
    call add(diffs, diff)
  endfor

  " TODO: Consider changes of all filers.
  let ops = self._arbitrator.decide_operations(diffs[0])

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

  let reconciler = efiler#Reconciler#new(reconciler_work_dir)
  call reconciler.apply(ops)
endfunction
