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
  elseif exists('*deletebufline')
    call deletebufline(a:buf, a:first, a:last)
  elseif a:first < a:last
    let current_bufnr = bufnr('%')
    try
      execute 'silent keepalt buffer' a:buf
      execute 'silent ' . a:first . ',' . a:last . 'delete'
    finally
      execute 'silent keepalt buffer' current_bufnr
    endtry
  endif
endfunction
