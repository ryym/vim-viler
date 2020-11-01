let s:Checker = {}

function! viler#diff#Checker#new(node_store) abort
  let checker = deepcopy(s:Checker)
  let checker._walker = viler#diff#Walker#new()
  let checker._node_store = a:node_store
  return checker
endfunction

function! s:Checker.is_dirty(dir, buf, commit_id) abort
  let ctx = s:new_walk_ctx(a:commit_id)
  let filetree = viler#Filetree#from_buf(a:buf, self._node_store)
  let start_lnum = get(a:dir, 'lnum', a:buf.lnum_first())
  call self._walker.walk_tree(a:dir, filetree.iter_from(start_lnum), ctx)
  return ctx.is_dirty
endfunction

function! s:new_walk_ctx(commit_id) abort
  let ctx = deepcopy(s:WalkCtx)
  let ctx.commit_id = a:commit_id
  let ctx.is_dirty = 0
  return ctx
endfunction

let s:WalkCtx = {}

function! s:WalkCtx.on_empty_line(...) abort
  let self.is_dirty = 1
endfunction
function! s:WalkCtx.on_new_file(...) abort
  let self.is_dirty = 1
endfunction
function! s:WalkCtx.on_moved_file(dir, row, src) abort
  let self.is_dirty = 1
endfunction
function! s:WalkCtx.on_deleted_file(...) abort
  let self.is_dirty = 1
endfunction
