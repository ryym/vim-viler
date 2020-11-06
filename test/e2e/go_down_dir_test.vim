let s:suite = themis#suite('E2E')
let s:assert = themis#helper('assert')
let s:t = viler#testutil#e2e#setup(s:suite)

function! s:suite.go_down_dir() abort
  call s:t.work_dir.make_files([
    \   'd1/',
    \   '  a',
    \   '  b',
    \ ])

  call viler#open(s:t.work_dir.path)
  call s:assert.equals(s:t.displayed_lines(), [s:t.work_dir.path, 'd1/'], 'initial lines')

  call cursor(2, 1)
  call viler#open_cursor_file()

  let want_lines = [viler#Path#join(s:t.work_dir.path, 'd1') . '/', 'a', 'b']
  call s:assert.equals(s:t.displayed_lines(), want_lines, 'lines after go-down d1/')
endfunction
