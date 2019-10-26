let s:Checker = {}

function! viler#diff#Checker#new(node_store) abort
  let checker = deepcopy(s:Checker)
  let checker._walker = viler#diff#Walker#new(a:node_store)
  return checker
endfunction

function! s:Checker.is_dirty(dir, buf) abort
  let handler = s:new_handler()
  call self._walker.walk_tree(a:dir, a:buf, handler)
  return handler.is_dirty
endfunction

function! s:new_handler() abort
  let handler = deepcopy(s:Handler)
  let handler.is_dirty = 0
  return handler
endfunction

let s:Handler = {}

function! s:Handler.on_new_file(...) abort
  let self.is_dirty = 1
endfunction
function! s:Handler.on_moved_file(dir, row, src) abort
  let self.is_dirty = 1
endfunction
function! s:Handler.on_deleted_file(...) abort
  let self.is_dirty = 1
endfunction
