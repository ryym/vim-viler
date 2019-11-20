function! viler#Path#join(a, b) abort
  let a = viler#Path#trim_slash(a:a)
  return a:b is# '' ? a : a . '/' . a:b
endfunction

function! viler#Path#trim_slash(path) abort
  if a:path[len(a:path) - 1] is# '/'
    return a:path[0:-2]
  endif
  return a:path
endfunction
