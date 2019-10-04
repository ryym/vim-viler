let s:Arbitrator = {}

function! efiler#Arbitrator#new() abort
  let arbitrator = deepcopy(s:Arbitrator)
  return arbitrator
endfunction

" TODO: Merge multiple diffs (and validate the final result).
function! s:Arbitrator.decide_operations(diff) abort
  let op = s:new_operation()

  let op.add = a:diff.added

  let deleted = {}
  for path in a:diff.deleted
    let deleted[path] = 1
  endfor

  let moves = {}
  for entry in a:diff.copied
    if has_key(deleted, entry.src_path)
      let moves[entry.src_path] = entry
    else
      call add(op.copy, entry)
    endif
  endfor

  let op.move = values(moves)
  let op.delete = a:diff.deleted->filter('!has_key(moves, v:val)')

  return op
endfunction

function! s:new_operation() abort
  return {
    \   'add': [],
    \   'copy': [],
    \   'move': [],
    \   'delete': [],
    \ }
endfunction
