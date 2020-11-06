let s:suite = themis#suite('E2E')
let s:assert = themis#helper('assert')
let s:t = viler#testutil#e2e#setup(s:suite)

function! s:suite.open_filer_for_specified_dir() abort
  call s:t.work_dir.make_files([
    \   'a',
    \   'b',
    \ ])
  call viler#open(s:t.work_dir.path)
  call s:assert.equals(s:t.displayed_lines(), [s:t.work_dir.path, 'a', 'b'])
endfunction
