let s:suite = themis#suite('E2E')
let s:assert = themis#helper('assert')
let s:t = viler#testutil#e2e#setup(s:suite)

function! s:suite.delete_one_file() abort
  call s:t.work_dir.make_files([
    \   'a',
    \   'b',
    \ ])

  call viler#open(s:t.work_dir.path)
  call s:assert.equals(s:t.displayed_lines(), [s:t.work_dir.path, 'a', 'b'], 'initial lines')

  " Delete the line b and save.
  execute '3delete'
  call s:t.write_buffer()

  " Check lines on filer.
  call s:assert.equals(s:t.displayed_lines(), [s:t.work_dir.path, 'a'], 'lines after write')

  " Check actual files.
  let ffs = viler#testutil#FlistFs#create()
  let got = ffs.files_to_flist(s:t.work_dir.path)
  call s:assert.equals(got.lines(), ['a'], 'actual files after write')
endfunction
