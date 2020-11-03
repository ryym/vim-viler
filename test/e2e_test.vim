" Test cases which uses only top level viler functions.

let s:suite = themis#suite('E2E')
let s:assert = themis#helper('assert')

let s:hooks = g:t.hooks()

" Manage buffers to clean up after each test.
let s:bufs = g:t.use_buffers(s:hooks)

function! s:hooks.before_each.prepare_work_dir() abort
  let s:work_root = tempname()
  let s:work_dir = s:work_root . '/work/'
  if isdirectory(s:work_root)
    call delete(s:work_root, 'rf')
  endif
  call mkdir(s:work_dir, 'p')
endfunction

function! s:hooks.after_each.clear_work_dir() abort
  call delete(s:work_root, 'rf')
endfunction

function! s:hooks.before_each.register_buf() abort
  call s:bufs.add(bufnr('%'))
endfunction

call s:hooks.register_to(s:suite)

" ===============

function! s:setup_files(lines) abort
  let flist = viler#testutil#Flist#new(a:lines)
  let ffs = viler#testutil#FlistFs#create()
  call ffs.flist_to_files(s:work_dir, flist)
endfunction

function! s:strip_meta_from_lines(lines)
  return map(a:lines, { i, l -> substitute(l, '\v\s+(/\||\|).+', '', '') })
endfunction

function! s:displayed_lines()
  return s:strip_meta_from_lines(getline(1, '$'))
endfunction

" Do :write and throw if it fails.
function! s:write_buffer()
  let bnr = bufnr('%')

  redir => output
  try
    execute 'write'
  finally
    redir END
  endtry

  if output =~# 'E\d\+'
    call g:t.log(output)
    throw 'buffer write seems failed. See output log.'
  endif
endfunction

" ===============

function! s:suite.open_filer_for_specified_dir() abort
  call s:setup_files([
    \   'a',
    \   'b',
    \ ])
  call viler#open(s:work_dir)
  call s:assert.equals(s:displayed_lines(), [s:work_dir, 'a', 'b'])
endfunction

function! s:suite.toggle_tree() abort
  call s:setup_files([
    \   'd1/',
    \   '  a/',
    \   '    a1',
    \   '  b/',
    \   '    b1',
    \ ])

  call viler#open(s:work_dir)
  call s:assert.equals(s:displayed_lines(), [s:work_dir, 'd1/'], 'initial lines')

  call cursor(2, 1)
  call viler#toggle_tree()

  let want_lines = [
    \   s:work_dir,
    \   'd1/',
    \   '  a/',
    \   '  b/',
    \ ]
  call s:assert.equals(s:displayed_lines(), want_lines, 'after open d1/',)

  call cursor(4, 1)
  call viler#toggle_tree()

  let want_lines = [
    \   s:work_dir,
    \   'd1/',
    \   '  a/',
    \   '  b/',
    \   '    b1',
    \ ]
  call s:assert.equals(s:displayed_lines(), want_lines, 'after open d1/b/',)

  call cursor(4, 1)
  call viler#toggle_tree()

  let want_lines = [
    \   s:work_dir,
    \   'd1/',
    \   '  a/',
    \   '  b/',
    \ ]
  call s:assert.equals(s:displayed_lines(), want_lines, 'after close d1/b/',)

  call cursor(2, 1)
  call viler#toggle_tree()

  call s:assert.equals(s:displayed_lines(), [s:work_dir, 'd1/'], 'after close d1/',)
endfunction

function! s:suite.keep_buf_states_over_refresh() abort
  call s:setup_files([
    \   'd1/',
    \   '  a',
    \   'd2/',
    \   '  b',
    \ ])

  call viler#open(s:work_dir)
  call s:assert.equals(s:displayed_lines(), [s:work_dir, 'd1/', 'd2/'], 'initial lines')

  " Open d1/.
  call cursor(2, 1)
  call viler#toggle_tree()

  " Put a cursor to last line (d2/).
  call cursor(4, 1)

  " Add a file outside of Viler.
  let fs = viler#lib#Fs#new()
  call fs.make_dir(viler#Path#join(s:work_dir, 'd1/b'))

  call viler#refresh()

  let want_lines = [
    \   s:work_dir,
    \   'd1/',
    \   '  b/',
    \   '  a',
    \   'd2/',
    \ ]
  call s:assert.equals(s:displayed_lines(), want_lines, 'after refresh')
  call s:assert.equals(getpos('.')[1], 4, 'cursor position lnum')
endfunction

function! s:suite.go_down_dir() abort
  call s:setup_files([
    \   'd1/',
    \   '  a',
    \   '  b',
    \ ])

  call viler#open(s:work_dir)
  call s:assert.equals(s:displayed_lines(), [s:work_dir, 'd1/'], 'initial lines')

  call cursor(2, 1)
  call viler#open_cursor_file()

  let want_lines = [viler#Path#join(s:work_dir, 'd1') . '/', 'a', 'b']
  call s:assert.equals(s:displayed_lines(), want_lines, 'lines after go-down d1/')
endfunction

function! s:suite.go_up_dir() abort
  call s:setup_files([
    \   'd1/',
    \   '  a',
    \   '  b',
    \ ])

  let initial_dir = viler#Path#join(s:work_dir, 'd1') . '/'

  call viler#open(initial_dir)
  call s:assert.equals(s:displayed_lines(), [initial_dir, 'a', 'b'], 'initial lines')

  call viler#go_up_dir()
  call s:assert.equals(s:displayed_lines(), [s:work_dir, 'd1/'], 'lines after go-up')
endfunction

function! s:suite.add_one_file_to_last() abort
  call s:setup_files([
    \   'a',
    \   'b',
    \ ])

  call viler#open(s:work_dir)
  call s:assert.equals(s:displayed_lines(), [s:work_dir, 'a', 'b'], 'initial lines')

  " Add a line c and save.
  call append('$',  'c')
  call s:write_buffer()

  " Check lines on filer.
  call s:assert.equals(s:displayed_lines(), [s:work_dir, 'a', 'b', 'c'], 'lines after write')

  " Check actual files.
  let ffs = viler#testutil#FlistFs#create()
  let got = ffs.files_to_flist(s:work_dir)
  call s:assert.equals(got.lines(), ['a', 'b', 'c'], 'actual files after write')
endfunction

function! s:suite.add_one_file_to_middle() abort
  call s:setup_files([
    \   'a',
    \   'b',
    \ ])

  call viler#open(s:work_dir)
  call s:assert.equals(s:displayed_lines(), [s:work_dir, 'a', 'b'], 'initial lines')

  " Add a line c and put a cursor on it.
  call append(2,  'c')
  call cursor(3, 1)
  call s:assert.equals(s:displayed_lines(), [s:work_dir, 'a', 'c', 'b'], 'lines before write')

  call s:write_buffer()
  call s:assert.equals(s:displayed_lines(), [s:work_dir, 'a', 'b', 'c'], 'lines after write')

  " Check actual files.
  let ffs = viler#testutil#FlistFs#create()
  let got = ffs.files_to_flist(s:work_dir)
  call s:assert.equals(got.lines(), ['a', 'b', 'c'], 'actual files after write')

  " Check the cursor position follows the line c.
  call s:assert.equals(getpos('.')[1], 4, 'cursor position')
endfunction

function! s:suite.copy_one_file() abort
  call s:setup_files([
    \   'a content:foo',
    \   'b',
    \ ])

  call viler#open(s:work_dir)
  call s:assert.equals(s:displayed_lines(), [s:work_dir, 'a', 'b'], 'initial lines')

  " Copy the line a.
  execute '2copy 2'
  execute '3s/^a/a2'
  call s:write_buffer()

  " Check lines on filer.
  call s:assert.equals(s:displayed_lines(), [s:work_dir, 'a', 'a2', 'b'], 'lines after write')

  " Check actual files.
  let ffs = viler#testutil#FlistFs#create()
  let got = ffs.files_to_flist(s:work_dir)
  let want = ['a content:foo', 'a2 content:foo', 'b']
  call s:assert.equals(got.lines(), want, 'actual files after write')
endfunction

function! s:suite.rename_one_file() abort
  call s:setup_files([
    \   'a content:foo',
    \   'b',
    \ ])

  call viler#open(s:work_dir)

  call s:assert.equals(s:displayed_lines(), [s:work_dir, 'a', 'b'], 'initial lines')

  " Rename the line a and save.
  execute '2s/^a/_a'
  call s:write_buffer()

  " Check lines on filer.
  call s:assert.equals(s:displayed_lines(), [s:work_dir, '_a', 'b'], 'lines after write')

  " Check actual files.
  let ffs = viler#testutil#FlistFs#create()
  let got = ffs.files_to_flist(s:work_dir)
  call s:assert.equals(got.lines(), ['_a content:foo', 'b'], 'actual files after write')
endfunction

function! s:suite.delete_one_file() abort
  call s:setup_files([
    \   'a',
    \   'b',
    \ ])

  call viler#open(s:work_dir)
  call s:assert.equals(s:displayed_lines(), [s:work_dir, 'a', 'b'], 'initial lines')

  " Delete the line b and save.
  execute '3delete'
  call s:write_buffer()

  " Check lines on filer.
  call s:assert.equals(s:displayed_lines(), [s:work_dir, 'a'], 'lines after write')

  " Check actual files.
  let ffs = viler#testutil#FlistFs#create()
  let got = ffs.files_to_flist(s:work_dir)
  call s:assert.equals(got.lines(), ['a'], 'actual files after write')
endfunction
