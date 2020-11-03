" Test cases which uses only top level viler functions.

let s:suite = themis#suite('E2E')
let s:assert = themis#helper('assert')

let s:hooks = g:t.hooks()

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

function! s:hooks.after_each.wipeout_buffer() abort
  silent execute 'bwipeout!' bufnr('%')
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

  call viler#refresh()

  let want_lines = [
    \   s:work_dir,
    \   'd1/',
    \   '  a',
    \   'd2/'
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
