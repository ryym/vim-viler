function! viler#Path#join(a, b) abort
  if a:a[len(a:a) - 1] == '/'
    return a:a . a:b
  endif
  return a:a . '/' . a:b
endfunction
