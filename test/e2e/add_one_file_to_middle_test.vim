let s:suite = themis#suite('E2E')
let s:assert = themis#helper('assert')
let s:t = viler#testutil#e2e#setup(s:suite)

function! s:suite.add_one_file_to_middle() abort
  call s:t.work_dir.make_files([
    \   'a',
    \   'b',
    \ ])

  call viler#open(s:t.work_dir.path)
  call s:assert.equals(s:t.displayed_lines(), [s:t.work_dir.path, 'a', 'b'], 'initial lines')

  " Add a line c and put a cursor on it.
  call append(2,  'c')
  call cursor(3, 1)
  call s:assert.equals(s:t.displayed_lines(), [s:t.work_dir.path, 'a', 'c', 'b'], 'lines before write')

  call s:t.write_buffer()
  call s:assert.equals(s:t.displayed_lines(), [s:t.work_dir.path, 'a', 'b', 'c'], 'lines after write')

  " Check actual files.
  let ffs = viler#testutil#FlistFs#create()
  let got = ffs.files_to_flist(s:t.work_dir.path)
  call s:assert.equals(got.lines(), ['a', 'b', 'c'], 'actual files after write')

  " Check the cursor position follows the line c.
  call s:assert.equals(getpos('.')[1], 4, 'cursor position')
endfunction
