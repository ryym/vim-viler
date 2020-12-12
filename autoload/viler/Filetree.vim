" Filetree abstracts the underlying data structure such as Buffer.
" This is useful for testing.
let s:Filetree = {}

function! viler#Filetree#from_buf(buf, node_store) abort
  let tree = deepcopy(s:Filetree)
  let tree._buf = a:buf
  let tree._node_store = a:node_store
  return tree
endfunction

function! s:Filetree.current_dir_path() abort
  return self._buf.current_dir().path
endfunction

function! s:Filetree.associated_node(row) abort
  return self._node_store.get_node(a:row.node_id)
endfunction

function! s:Filetree.has_node_for(path) abort
  let node = self._node_store.try_get_node_from_path(a:path)
  if type(node) is# v:t_number
    return 0
  endif
  return self._buf.should_be_displayed(node.id)
endfunction

function! s:Filetree.iter() abort
  return s:new_iter(self, self._buf.lnum_first())
endfunction

function! s:Filetree.iter_from(lnum) abort
  return s:new_iter(self, a:lnum)
endfunction

let s:Iter = {}

function! s:new_iter(filetree, start_lnum) abort
  let iter = copy(s:Iter)
  let iter.filetree = a:filetree
  let iter._lnum = a:start_lnum
  let iter._lnum_last = a:filetree._buf.lnum_last()
  return iter
endfunction

function! s:Iter.has_next() abort
  return self._lnum <=# self._lnum_last
endfunction

function! s:Iter.lnum() abort
  return self._lnum
endfunction

function! s:Iter.peek() abort
  return self.filetree._buf.row_info(self._lnum)
endfunction

function! s:Iter.next() abort
  if !self.has_next()
    throw 'Filetree iterator is at end'
  endif
  let row = self.peek()
  let self._lnum += 1
  return row
endfunction
