let s:suite = themis#suite('Bufs')
let s:assert = themis#helper('assert')

let s:hooks = g:t.hooks()
let s:bufs = g:t.use_buffers(s:hooks, {})

call s:hooks.register_to(s:suite)

" NOTE: I don't know why but `setbufline` does not work during tests.
" It seems that we cannot write to a hidden buffer.

function! s:suite.open_buffers_and_wipeout_them1() abort
  let buf1 = s:bufs.open()
  let buf2 = s:bufs.open()
  call s:assert.equals(len(getbufinfo()), 2, 'number of buffers')

  call setline(1, ['a', 'b'])
  call s:assert.equals(getbufline(buf1, 1, 3), [])
  call s:assert.equals(getbufline(buf2, 1, 3), ['a', 'b'])
endfunction

function! s:suite.open_buffers_and_wipeout_them2() abort
  let buf1 = s:bufs.open()
  let buf2 = s:bufs.open()
  let buf3 = s:bufs.open()
  call s:assert.equals(len(getbufinfo()), 3, 'number of buffers')

  silent execute 'buffer' buf1
  call setline(1, ['111'])
  call s:assert.equals(getbufline(buf1, 1, 3), ['111'])
  call s:assert.equals(getbufline(buf3, 1, 3), [])
endfunction
