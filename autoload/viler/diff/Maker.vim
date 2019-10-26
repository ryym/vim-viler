let s:Maker = {}

function! viler#diff#Maker#new(node_store) abort
  let maker = deepcopy(s:Maker)
  let maker._node_store = a:node_store
  let maker._walker = viler#diff#Walker#new(a:node_store)
  return maker
endfunction

function! s:Maker.gather_changes(buf, diff) abort
  let dir_path = a:buf.current_dir().path
  let dir = {
    \   'path': dir_path,
    \   'depth': 0,
    \ }
  let handler = s:new_handler(a:diff)
  call self._walker.walk_tree(dir, a:buf, handler)
endfunction

let s:Handler = {}

function! s:new_handler(diff) abort
  let handler = deepcopy(s:Handler)
  let handler.diff = a:diff
  return handler
endfunction

function! s:Handler.on_new_file(dir, row) abort
  call self.diff.new_file(a:dir.path, a:row.name, {'is_dir': a:row.is_dir})
endfunction

function! s:Handler.on_moved_file(dir, row, src) abort
  call self.diff.moved_file(a:dir.path, a:row.name, {
    \   'abs_path': a:src.path,
    \   'name': a:src.node.name,
    \   'is_dir': a:src.node.is_dir,
    \ })
endfunction

function! s:Handler.on_deleted_file(dir, file) abort
  call self.diff.deleted_file(a:dir.path, a:file.name, {'is_dir': a:file.is_dir})
endfunction
