let s:suite = themis#suite('E2E')
let s:assert = themis#helper('assert')
let s:t = viler#testutil#e2e#setup(s:suite)

function! s:suite.keep_buf_states_over_refresh() abort
  call s:t.work_dir.make_files([
    \   'd1/',
    \   '  a',
    \   'd2/',
    \   '  b',
    \ ])

  call viler#open(s:t.work_dir.path)
  call s:assert.equals(s:t.displayed_lines(), [s:t.work_dir.path, 'd1/', 'd2/'], 'initial lines')

  " Open d1/.
  call cursor(2, 1)
  call viler#toggle_tree()

  " Put a cursor to last line (d2/).
  call cursor(4, 1)

  " Add a file outside of Viler.
  let fs = viler#lib#Fs#new()
  call fs.make_dir(viler#Path#join(s:t.work_dir.path, 'd1/b'))

  call viler#refresh()

  let want_lines = [
    \   s:t.work_dir.path,
    \   'd1/',
    \   '  b/',
    \   '  a',
    \   'd2/',
    \ ]
  call s:assert.equals(s:t.displayed_lines(), want_lines, 'after refresh')
  call s:assert.equals(getpos('.')[1], 4, 'cursor position lnum')
endfunction
