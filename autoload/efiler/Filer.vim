let s:Filer = {}

function! efiler#Filer#new(buf, id_gen) abort
  let filer = deepcopy(s:Filer)
  let filer._buf = a:buf
  let filer._id = a:id_gen
  return filer
endfunction

function! s:Filer.display(dir) abort
  let nodes = self._list_children(a:dir)
  call self._buf.display_nodes(nodes)
endfunction

function! s:Filer._make_node(dir, name) abort
  let id = self._id.make()
  return efiler#Node#new(id, a:dir . '/' . a:name)
endfunction

function! s:Filer._list_children(dir) abort
  let nodes = []
  for name in readdir(a:dir)
    let node = self._make_node(a:dir, name)
    call add(nodes, node)
  endfor
  return nodes
endfunction

