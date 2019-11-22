function! viler#lib#Buf#set_lines(buf, lnum, lines) abort
  if has('nvim')
    let start = a:lnum - 1
    let end = start + len(a:lines)
    call nvim_buf_set_lines(a:buf, start, end, 0, a:lines)
  else
    call setbufline(a:buf, a:lnum, a:lines)
  endif
endfunction

function! viler#lib#Buf#delete_lines(buf, first, last) abort
  if has('nvim')
    call nvim_buf_set_lines(a:buf, a:first - 1, a:last, 0, [])
  else
    call deletebufline(a:buf, a:first, a:last)
  endif
endfunction
