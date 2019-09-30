let s:Filer = {'_id': 0, '_nodes': {}}

function! efiler#Filer#new(id, buf, id_gen) abort
  let filer = deepcopy(s:Filer)
  let filer._buf = a:buf
  let filer._id = a:id
  let filer._node_id = a:id_gen
  return filer
endfunction

function! s:Filer.display(dir) abort
  let self._nodes = {}
  let nodes = self._list_children(a:dir)
  call self._buf.display_nodes(nodes)
endfunction

function! s:Filer._make_node(dir, name) abort
  let id = self._node_id.make()
  return efiler#Node#new(id, a:dir . '/' . a:name)
endfunction

function! s:Filer._list_children(dir) abort
  let nodes = []
  for name in readdir(a:dir)
    let node = self._make_node(a:dir, name)
    let self._nodes[node.id] = node
    call add(nodes, node)
  endfor
  return nodes
endfunction

function! s:Filer._node(id) abort
  if !has_key(self._nodes, a:id)
    throw '[efiler] Unknown Node ID' a:id
  endif
  return self._nodes[a:id]
endfunction

function! s:Filer.go_down_cursor_dir() abort
  let row = self._buf.node_row('.')
  let node = self._node(row.node_id)
  call self.display(node.abs_path())
endfunction
