let s:suite = themis#suite('E2E')
let s:assert = themis#helper('assert')
let s:t = viler#testutil#e2e#setup(s:suite)

function! s:suite.undo_redo_dir_change() abort
  call s:t.work_dir.make_files([
    \   'd1/',
    \   '  foo',
    \   'a',
    \   'b',
    \ ])

  call viler#open(s:t.work_dir.path)
  call s:t.break_undo_sequence()

  let initial_lines = [s:t.work_dir.path, 'd1/', 'a', 'b']
  call s:assert.equals(s:t.displayed_lines(), initial_lines, 'initial lines')

  call cursor(2, 1)
  call viler#open_cursor_file()

  let lines_after_cd = [s:t.work_dir.path . 'd1/', 'foo']
  call s:assert.equals(s:t.displayed_lines(), lines_after_cd, 'lines after go-down into d1/')

  call viler#undo()
  call s:assert.equals(s:t.displayed_lines(), initial_lines, 'lines after undo')

  call viler#redo()
  call s:assert.equals(s:t.displayed_lines(), lines_after_cd, 'lines after redo')
endfunction
