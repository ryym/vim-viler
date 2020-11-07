let s:suite = themis#suite('E2E')
let s:assert = themis#helper('assert')
let s:t = viler#testutil#e2e#setup(s:suite)

function! s:suite.rename_and_rerename() abort
  call s:t.work_dir.make_files([
    \   'a content:foo',
    \   'b',
    \ ])

  call viler#open(s:t.work_dir.path)

  call s:assert.equals(s:t.displayed_lines(), [s:t.work_dir.path, 'a', 'b'], 'initial lines')

  " Rename the line a to z.
  execute '2s/^a/z'
  call cursor(2, 1)
  call s:t.write_buffer()

  " Check lines on filer.
  call s:assert.equals(s:t.displayed_lines(), [s:t.work_dir.path, 'b', 'z'], 'lines after a->z')
  call s:assert.equals(getpos('.')[1], 3, 'cursor position lnum after a->z')

  " Check actual files.
  let ffs = viler#testutil#FlistFs#create()
  let got = ffs.files_to_flist(s:t.work_dir.path)
  call s:assert.equals(got.lines(), ['b', 'z content:foo'], 'actual files after a->z')

  "Re-rename the line z to a.
  execute '3s/^z/a'
  call cursor(3, 1)
  call s:t.write_buffer()

  " Check lines on filer.
  call s:assert.equals(s:t.displayed_lines(), [s:t.work_dir.path, 'a', 'b'], 'lines after z->a')
  call s:assert.equals(getpos('.')[1], 2, 'cursor position lnum after z->a')

  " Check actual files.
  let ffs = viler#testutil#FlistFs#create()
  let got = ffs.files_to_flist(s:t.work_dir.path)
  call s:assert.equals(got.lines(), ['a content:foo', 'b'], 'actual files after write')
endfunction
