" Split a string to a pair of head and tail.
" You can specify the pattern of head.
" The unmatched part of string becomes a tail.
function! viler#lib#Str#split_head_tail(str, head_pat)
  let head_end = matchend(a:str, a:head_pat, 0, 1)
  if head_end == 0 || head_end == -1
    return ['', a:str]
  endif

  let head = a:str[0:head_end-1]
  let tail = a:str[head_end:]
  return [head, tail]
endfunction
