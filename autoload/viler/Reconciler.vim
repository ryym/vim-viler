let s:Reconciler = {}

function! viler#Reconciler#new(id_gen, work_dir_path) abort
  let reconciler = deepcopy(s:Reconciler)
  let reconciler._id_gen = a:id_gen
  let reconciler._unifier = viler#diff#Unifier#new(a:id_gen)
  let reconciler._validator = viler#diff#Validator#new()
  let reconciler._fs = viler#Fs#new()
  let reconciler._work_dir_path = a:work_dir_path
  return reconciler
endfunction

function! s:Reconciler.reconcile(current_commit_id, drafts) abort
  let diff_maker = viler#diff#Maker#new()

  let diffs = []
  for draft in a:drafts
    if draft.commit_id < a:current_commit_id
      throw "[viler] draft's state is old. Did you use undo? Undo over save is not supported."
    endif
    let diff = viler#diff#Diff#new(self._id_gen)
    call diff_maker.gather_changes(a:current_commit_id, draft.filetree, diff)
    call add(diffs, diff)
  endfor

  let final_diff = self._unifier.unify_diffs(diffs)
  let errs = self._validator.validate_diff(final_diff)
  if len(errs) > 0
    throw '[viler] ' . string(errs)
  endif

  " TODO: Delete old work files periodically.
  let work_path = viler#Path#join(self._work_dir_path, localtime())
  call mkdir(work_path, "p")
  let work_dir = { 'path': work_path }
  let applier = viler#diff#Applier#new(final_diff, self._fs, work_dir)
  call applier.apply_changes()
endfunction
