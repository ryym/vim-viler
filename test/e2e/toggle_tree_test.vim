let s:suite = themis#suite('E2E')
let s:assert = themis#helper('assert')
let s:t = viler#testutil#e2e#setup(s:suite)

function! s:suite.toggle_tree() abort
  call s:t.work_dir.make_files([
    \   'd1/',
    \   '  a/',
    \   '    a1',
    \   '  b/',
    \   '    b1',
    \ ])

  call viler#open(s:t.work_dir.path)
  call s:assert.equals(s:t.displayed_lines(), [s:t.work_dir.path, 'd1/'], 'initial lines')

  call cursor(2, 1)
  call viler#toggle_tree()

  let want_lines = [
    \   s:t.work_dir.path,
    \   'd1/',
    \   '  a/',
    \   '  b/',
    \ ]
  call s:assert.equals(s:t.displayed_lines(), want_lines, 'after open d1/',)

  call cursor(4, 1)
  call viler#toggle_tree()

  let want_lines = [
    \   s:t.work_dir.path,
    \   'd1/',
    \   '  a/',
    \   '  b/',
    \   '    b1',
    \ ]
  call s:assert.equals(s:t.displayed_lines(), want_lines, 'after open d1/b/',)

  call cursor(4, 1)
  call viler#toggle_tree()

  let want_lines = [
    \   s:t.work_dir.path,
    \   'd1/',
    \   '  a/',
    \   '  b/',
    \ ]
  call s:assert.equals(s:t.displayed_lines(), want_lines, 'after close d1/b/',)

  call cursor(2, 1)
  call viler#toggle_tree()

  call s:assert.equals(s:t.displayed_lines(), [s:t.work_dir.path, 'd1/'], 'after close d1/')
endfunction
