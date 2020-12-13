let s:suite = themis#suite('E2E')
let s:assert = themis#helper('assert')
let s:t = viler#testutil#e2e#setup(s:suite)

function! s:suite.can_delete_with_multi_filers() abort
  call s:t.work_dir.make_files([
    \   'd1/',
    \   '  a content:aaa',
    \   'd2/',
    \   '  b content:bbb',
    \ ])

  " Open a filer1.
  let work_dir1_path = viler#Path#join(s:t.work_dir.path, 'd1') . '/'
  call viler#open(work_dir1_path)
  let buf1 = bufnr('%')
  call s:assert.equals(s:t.displayed_lines(), [work_dir1_path, 'a'], 'initial lines (buf1)')

  " Open a filer2.
  let work_dir2_path = viler#Path#join(s:t.work_dir.path, 'd2') . '/'
  call viler#open(work_dir2_path)
  let buf2 = bufnr('%')
  call s:t.bufs.add(buf2)
  call s:assert.equals(s:t.displayed_lines(), [work_dir2_path, 'b'], 'initial lines (buf2)')

  " Back to filer1.
  execute 'buffer' buf1
  " Delete line a.
  execute '2delete'
  call s:assert.equals(s:t.displayed_lines(), [work_dir1_path], 'lines after delete (buf1)')

  call s:t.write_buffer()

  " Check lines on filer1.
  call s:assert.equals(s:t.displayed_lines(), [work_dir1_path], 'lines after write (buf1)')

  " Check actual files.
  let ffs = viler#testutil#FlistFs#create()
  let got = ffs.files_to_flist(s:t.work_dir.path)
  let want = [
    \   'd1/',
    \   'd2/',
    \   '  b content:bbb',
    \ ]
  call s:assert.equals(got.lines(), want, 'actual files after write')
endfunction
