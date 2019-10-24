let s:Reconciler = {}

function! viler#Reconciler#new(id_gen, node_store, work_dir_path) abort
  let reconciler = deepcopy(s:Reconciler)
  let reconciler._id_gen = a:id_gen
  let reconciler._node_store = a:node_store
  let reconciler._unifier = viler#diff#Unifier#new(a:id_gen)
  let reconciler._validator = viler#diff#Validator#new()
  let reconciler._fs = viler#Fs#new()
  let reconciler._work_dir_path = a:work_dir_path
  return reconciler
endfunction

function! s:Reconciler.reconcile(filers) abort
  let diff_maker = viler#diff#Maker#new(self._node_store)

  let diffs = []
  for filer in a:filers
    let diff = viler#diff#Diff#new(self._id_gen)
    call diff_maker.gather_changes(filer.buffer(), diff)
    call add(diffs, diff)
  endfor

  let final_diff = self._unifier.unify_diffs(diffs)
  let errs = self._validator.validate_diff(final_diff)
  if len(errs) > 0
    throw '[viler] ' . string(errs)
  endif

  let work_dir = { 'path': self._work_dir_path }
  let applier = viler#diff#Applier#new(final_diff, self._fs, work_dir)
  call applier.apply_changes()
endfunction
