let s:suite = themis#suite('E2E')
let s:assert = themis#helper('assert')
let s:t = viler#testutil#e2e#setup(s:suite)

function! s:suite.save_multi_filers() abort
  setlocal nohidden

  call s:t.work_dir.make_files([
    \   'd1/',
    \   '  a content:aa',
    \   'd2/',
    \   '  b content:bb',
    \ ])

  " Open a filer1.
  let work_dir1_path = viler#Path#join(s:t.work_dir.path, 'd1') . '/'
  call viler#open(work_dir1_path)
  let buf1 = bufnr('%')
  call s:assert.equals(s:t.displayed_lines(), [work_dir1_path, 'a'], 'initial lines (buf1)')

  " Rename the line a.
  execute '2s/^a/_a'

  " Open a filer2.
  let work_dir2_path = viler#Path#join(s:t.work_dir.path, 'd2') . '/'
  call viler#open(work_dir2_path)
  let buf2 = bufnr('%')
  call s:t.bufs.add(buf2)
  call s:assert.equals(s:t.displayed_lines(), [work_dir2_path, 'b'], 'initial lines (buf2)')

  " Rename the line b.
  execute '2s/^b/_b'

  call s:t.write_buffer()

  " Check lines on filer1.
  execute 'buffer' buf1
  call s:assert.equals(s:t.displayed_lines(), [work_dir1_path, '_a'], 'lines after write (buf1)')

  " Check lines on filer2.
  execute 'buffer' buf2
  call s:assert.equals(s:t.displayed_lines(), [work_dir2_path, '_b'], 'lines after write (buf2)')

  " Check actual files.
  let ffs = viler#testutil#FlistFs#create()
  let got = ffs.files_to_flist(s:t.work_dir.path)
  let want = [
  \   'd1/',
  \   '  _a content:aa',
  \   'd2/',
  \   '  _b content:bb',
  \ ]
  call s:assert.equals(got.lines(), want, 'actual files after write')
endfunction
