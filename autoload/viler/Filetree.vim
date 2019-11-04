" Filetree abstracts the underlying data structure such as Buffer.
" This is useful for testing.
let s:Filetree = {}

function! viler#Filetree#from_buf(buf, node_store) abort
  let tree = deepcopy(s:Filetree)
  let tree._buf = a:buf
  let tree._node_store = a:node_store
  return tree
endfunction

function! s:Filetree.lnum_first() abort
  return self._buf.lnum_first()
endfunction

function! s:Filetree.lnum_last() abort
  return self._buf.lnum_last()
endfunction

function! s:Filetree.current_dir_path() abort
  return self._buf.current_dir().path
endfunction

function! s:Filetree.row(idx) abort
  return self._buf.node_row(a:idx)
endfunction

function! s:Filetree.associated_node(row) abort
  return self._node_store.get_node(a:row.bufnr, a:row.node_id)
endfunction
