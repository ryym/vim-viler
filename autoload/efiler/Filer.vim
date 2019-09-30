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

  let dir_node = self._make_node(a:dir)
  let self._nodes[dir_node.id] = dir_node

  let nodes = self._list_children(a:dir)
  call self._buf.display_nodes(dir_node, nodes)
  call self._buf.reset_cursor()

  return {'dir': dir_node, 'nodes': nodes}
endfunction

function! s:Filer._make_node(abs_path) abort
  let id = self._node_id.make()
  return efiler#Node#new(id, a:abs_path)
endfunction

function! s:Filer._list_children(dir) abort
  let nodes = []
  for name in readdir(a:dir)
    let node = self._make_node(a:dir . '/' . name)
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
  let row = self._buf.node_row(self._buf.cursor_line())
  let node = self._node(row.node_id)
  call self.display(node.abs_path())
endfunction

function! s:Filer.go_up_dir() abort
  let dir_id = self._buf.current_dir_node_id()
  let dir_node = self._node(dir_id)
  let shown_nodes = self.display(dir_node.dir)

  let prev_dir_node_id = 0
  for node in shown_nodes.nodes
    if node.name == dir_node.name
      let prev_dir_node_id = node.id
      break
    endif
  endfor

  if 0 < prev_dir_node_id
    let lnum = self._buf.node_lnum(prev_dir_node_id)
    if 0 < lnum
      call self._buf.put_cursor(lnum, 1)
    endif
  endif
endfunction
