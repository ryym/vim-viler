let s:Draft = {}

function! viler#Draft#from_buf(buf, node_store) abort
  let commit_id = a:buf.current_dir().commit_id
  let filetree = viler#Filetree#from_buf(a:buf, a:node_store)
  return viler#Draft#new(commit_id, filetree)
endfunction

function! viler#Draft#new(commit_id, filetree) abort
  let draft = deepcopy(s:Draft)
  let draft.commit_id = a:commit_id
  let draft.filetree = a:filetree
  return draft
endfunction
