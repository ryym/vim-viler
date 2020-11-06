let s:suite = themis#suite('E2E')
let s:assert = themis#helper('assert')
let s:t = viler#testutil#e2e#setup(s:suite)

function! s:suite.add_one_file_to_last() abort
  call s:t.work_dir.make_files([
    \   'a',
    \   'b',
    \ ])

  call viler#open(s:t.work_dir.path)
  call s:assert.equals(s:t.displayed_lines(), [s:t.work_dir.path, 'a', 'b'], 'initial lines')

  " Add a line c and save.
  call append('$',  'c')
  call s:t.write_buffer()

  " Check lines on filer.
  call s:assert.equals(s:t.displayed_lines(), [s:t.work_dir.path, 'a', 'b', 'c'], 'lines after write')

  " Check actual files.
  let ffs = viler#testutil#FlistFs#create()
  let got = ffs.files_to_flist(s:t.work_dir.path)
  call s:assert.equals(got.lines(), ['a', 'b', 'c'], 'actual files after write')
endfunction
