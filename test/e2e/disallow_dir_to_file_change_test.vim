let s:suite = themis#suite('E2E')
let s:assert = themis#helper('assert')
let s:t = viler#testutil#e2e#setup(s:suite)

function! s:suite.disallow_dir_to_file_change() abort
  call s:t.work_dir.make_files([
    \   'a/',
    \   'b',
    \ ])

  call viler#open(s:t.work_dir.path)
  call s:assert.equals(s:t.displayed_lines(), [s:t.work_dir.path, 'a/', 'b'], 'initial lines')

  " Rename the line a/ to a.
  execute '2s/^a\//a'

  try
    call s:t.write_buffer()
  catch
    call s:assert.match(v:exception, '\[viler\] You cannot change file to directory')
  endtry

  " Check actual files.
  let ffs = viler#testutil#FlistFs#create()
  let got = ffs.files_to_flist(s:t.work_dir.path)
  call s:assert.equals(got.lines(), ['a/', 'b'], 'actual files after write')
endfunction
