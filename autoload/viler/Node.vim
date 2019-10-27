let s:Node = {
  \   'id': 0,
  \   'dir': '',
  \   'name': '',
  \   'is_dir': 0,
  \ }

function! viler#Node#new(id, abs_path) abort
  let node = deepcopy(s:Node)
  let node.id = a:id

  let node.dir = fnamemodify(a:abs_path, ':h')
  let node.name = fnamemodify(a:abs_path, ':t')
  let node.is_dir = isdirectory(a:abs_path)
  return node
endfunction

function! s:Node.abs_path() abort
  return viler#Path#join(self.dir, self.name)
endfunction
