" FlistFiletree is a mock object of viler#Filetree, but based on Flist.
" Using this, you can do reconciliation programatically without
" manually opening a filer and editing the buffer.
let s:FlistFiletree = {}

function! viler#testutil#FlistFiletree#new(root_dir, flist) abort
  let tree = deepcopy(s:FlistFiletree)
  let tree._root_dir = a:root_dir
  let tree._flist = a:flist
  return tree
endfunction

function! s:FlistFiletree.current_dir_path() abort
  return self._root_dir
endfunction

function! s:FlistFiletree.associated_node(row) abort
  if has_key(a:row, 'src_path')
    let path = viler#Path#join(self._root_dir, a:row.src_path)
  else
    let dir = viler#Path#join(self._root_dir, a:row.dir)
    let path = viler#Path#join(dir, a:row.name)
  endif
  return viler#Node#new(0, path)
endfunction

function! s:FlistFiletree.iter() abort
  return s:new_iter(self)
endfunction

let s:Iter = {}

function! s:new_iter(filetree) abort
  let iter = copy(s:Iter)
  let iter.filetree = a:filetree
  let iter._iter = a:filetree._flist.iter()
  return iter
endfunction

function! s:Iter.has_next() abort
  return self._iter.has_next()
endfunction

function! s:Iter.lnum() abort
  return self._iter.lnum()
endfunction

function! s:Iter.peek() abort
  return self._iter.peek()
endfunction

function! s:Iter.next() abort
  return self._iter.next()
endfunction
