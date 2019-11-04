let s:Draft = {}

function! viler#Draft#new(buf, node_store) abort
  let draft = deepcopy(s:Draft)
  let draft.commit_id = a:buf.current_dir().commit_id
  let draft.filetree = viler#Filetree#from_buf(a:buf, a:node_store)
  return draft
endfunction
