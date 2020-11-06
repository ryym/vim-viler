let s:suite = themis#suite('E2E')
let s:assert = themis#helper('assert')
let s:t = viler#testutil#e2e#setup(s:suite)

function! s:suite.go_up_dir() abort
  call s:t.work_dir.make_files([
    \   'd1/',
    \   '  a',
    \   '  b',
    \ ])

  let initial_dir = viler#Path#join(s:t.work_dir.path, 'd1') . '/'

  call viler#open(initial_dir)
  call s:assert.equals(s:t.displayed_lines(), [initial_dir, 'a', 'b'], 'initial lines')

  call viler#go_up_dir()
  call s:assert.equals(s:t.displayed_lines(), [s:t.work_dir.path, 'd1/'], 'lines after go-up')
endfunction
