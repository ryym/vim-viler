let s:Maker = {}

function! viler#diff#Maker#new() abort
  let maker = deepcopy(s:Maker)
  let maker._walker = viler#diff#Walker#new()
  return maker
endfunction

function! s:Maker.gather_changes(commit_id, filetree, diff) abort
  let dir_path = a:filetree.current_dir_path()
  let dir = {
    \   'path': dir_path,
    \   'depth': 0,
    \ }
  let ctx = s:new_walk_ctx(a:commit_id, a:diff)
  call self._walker.walk_tree(dir, a:filetree.iter(), ctx)
endfunction

let s:WalkCtx = {}

function! s:new_walk_ctx(commit_id, diff) abort
  let ctx = deepcopy(s:WalkCtx)
  let ctx.diff = a:diff
  let ctx.commit_id = a:commit_id
  return ctx
endfunction

function! s:WalkCtx.on_empty_line(...) abort
  " Do nothing.
endfunction

function! s:WalkCtx.on_new_file(dir, row) abort
  call self.diff.new_file(a:dir.path, a:row.name, {'is_dir': a:row.is_dir})
endfunction

function! s:WalkCtx.on_moved_file(dir, row, src) abort
  call self.diff.moved_file(a:dir.path, a:row.name, {
    \   'abs_path': a:src.path,
    \   'name': a:src.node.name,
    \   'is_dir': a:src.node.is_dir,
    \ })
endfunction

function! s:WalkCtx.on_deleted_file(dir, file) abort
  call self.diff.deleted_file(a:dir.path, a:file.name, {'is_dir': a:file.is_dir})
endfunction
