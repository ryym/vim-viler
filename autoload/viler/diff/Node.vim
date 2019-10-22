let g:viler#diff#Node#will = {
  \   'stay': 0,
  \   'join': 1,
  \   'leave': 2,
  \ }

function! viler#diff#Node#new(id, parent_id, name, is_dir, will) abort
  let node = {
    \   'id': a:id,
    \   'parent': a:parent_id,
    \   'name': a:name,
    \   'is_dir': a:is_dir,
    \   'will': a:will,
    \ }
  if a:is_dir
    let node.children = {}
  endif
  return node
endfunction
