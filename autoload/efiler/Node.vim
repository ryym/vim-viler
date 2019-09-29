let s:Node = {
  \   'id': 0,
  \   'dir': '',
  \   'name': '',
  \   'is_dir': 0,
  \ }

function! efiler#Node#new(id, abs_path) abort
  let node = deepcopy(s:Node)
  let node.id = a:id
  let node.dir = fnamemodify(a:abs_path, ':h')
  let node.name = fnamemodify(a:abs_path, ':t')
  let node.is_dir = isdirectory(a:abs_path)
  if node.is_dir
    let node.name .= '/'
  endif
  return node
endfunction
