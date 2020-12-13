let s:suite = themis#suite('E2E')
let s:assert = themis#helper('assert')
let s:t = viler#testutil#e2e#setup(s:suite)

function! s:suite.edit_same_dir_in_multi_filers_test() abort
  setlocal nohidden

  call s:t.work_dir.make_files([
    \  'a',
    \  'b content:bb',
    \ ])

  " Open a filer1.
  call viler#open(s:t.work_dir.path)
  let buf1 = bufnr('%')
  call s:assert.equals(s:t.displayed_lines(), [s:t.work_dir.path, 'a', 'b'], 'initial lines (buf1)')

  " Add a line c.
  call append('$',  'c')

  " Open a filer2.
  call viler#open(s:t.work_dir.path)
  let buf2 = bufnr('%')
  call s:t.bufs.add(buf2)
  call s:assert.equals(s:t.displayed_lines(), [s:t.work_dir.path, 'a', 'b'], 'initial lines (buf2)')

  " Rename the line b.
  execute '3s/^b/_b'

  call s:t.write_buffer()

  let want_lines = [s:t.work_dir.path, '_b', 'a', 'c']

  " Check lines on filer1.
  execute 'buffer' buf1
  call s:assert.equals(s:t.displayed_lines(), want_lines, 'lines after write (buf1)')

  " Check lines on filer2.
  execute 'buffer' buf2
  call s:assert.equals(s:t.displayed_lines(), want_lines, 'lines after write (buf2)')

  " Check actual files.
  let ffs = viler#testutil#FlistFs#create()
  let got = ffs.files_to_flist(s:t.work_dir.path)
  call s:assert.equals(got.lines(), ['_b content:bb', 'a', 'c'], 'actual files after write')
endfunction
