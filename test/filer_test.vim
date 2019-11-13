let s:suite = themis#suite('Filer')
let s:assert = themis#helper('assert')

let s:hooks = g:t.hooks()
let s:bufs = g:t.use_buffers(s:hooks)

function! s:hooks.before_each.prepare_work_dir() abort
  let s:work_root = tempname()
  let s:work_dir = s:work_root . '/work'
  let s:filer_work_dir = s:work_root . '/filer'
  if isdirectory(s:work_root)
    call delete(s:work_root, 'rf')
  endif
  call mkdir(s:work_dir, 'p')
  call mkdir(s:filer_work_dir, 'p')
endfunction

function! s:hooks.after_each.clear_work_dir() abort
  call delete(s:work_root, 'rf')
endfunction

call s:hooks.register_to(s:suite)

function! s:open_filer(dir)
  let bufnr = s:bufs.open()
  let buffer = viler#Buffer#new()
  call buffer.bind(bufnr)

  let node_store = viler#NodeStore#new()
  let node_accessor = node_store.accessor_for(bufnr)
  let diff_checker = viler#diff#Checker#new(node_store)

  let filer = viler#Filer#new(
    \   0,
    \   buffer,
    \   node_accessor,
    \   diff_checker,
    \ )

  call filer.display(a:dir, {})
  return filer
endfunction

function! s:setup_files(lines) abort
  let flist = viler#testutil#Flist#new(a:lines)
  let ffs = viler#testutil#FlistFs#create()
  call ffs.flist_to_files(s:work_dir, flist)
endfunction

function! s:suite.open_filer_for_specified_dir() abort
  call s:setup_files([
    \   'a',
    \   'b',
    \ ])

  let filer = s:open_filer(s:work_dir)
  let buf = filer.buffer()

  call s:assert.equals(buf.shown_row_count(), 2, 'row count')

  let row = buf.node_row(buf.lnum_last())
  call s:assert.equals([row.name, row.is_dir], ['b', 0])
endfunction

function! s:suite.toggle_tree() abort
  call s:setup_files([
    \   'd1/',
    \   '  a/',
    \   '    a1',
    \   '  b/',
    \   '    b1',
    \ ])

  let filer = s:open_filer(s:work_dir)
  let buf = filer.buffer()

  call s:assert.equals(buf.shown_row_count(), 1, 'initial row count')

  call filer.toggle_tree_at(buf.lnum_first())

  call s:assert.equals(buf.shown_row_count(), 3, 'row count when open')
  let row = buf.node_row(buf.lnum_first() + 1)
  call s:assert.equals(row.name, 'a')

  call filer.toggle_tree_at(buf.lnum_first())
  call s:assert.equals(buf.shown_row_count(), 1, 'row count when closed')
endfunction

function! s:suite.keep_buf_states_over_refresh() abort
  call s:setup_files([
    \   'd1/',
    \   '  a',
    \   'd2/',
    \   '  b',
    \ ])

  let filer = s:open_filer(s:work_dir)
  let buf = filer.buffer()
  let first_lnum = buf.lnum_first()

  call filer.toggle_tree_at(first_lnum)
  call buf.put_cursor(first_lnum + 2, 2)
  call s:assert.equals(buf.shown_row_count(), 3, 'row count before refresh')

  call filer.refresh()
  call s:assert.equals(buf.shown_row_count(), 3, 'row count after refresh')
  call s:assert.equals(buf.lnum_cursor(), first_lnum + 2, 'cursor position')
endfunction
