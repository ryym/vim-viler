let s:suite = themis#suite('Filer')
let s:assert = themis#helper('assert')

function! s:suite.before_each() abort
  let s:work_root = tempname()
  let s:work_dir = s:work_root . '/work'
  let s:filer_work_dir = s:work_root . '/filer'
  if isdirectory(s:work_root)
    call delete(s:work_root, 'rf')
  endif
  call mkdir(s:work_dir, 'p')
  call mkdir(s:filer_work_dir, 'p')
endfunction

function! s:suite.after_each() abort
  call delete(s:work_root, 'rf')
endfunction

function! s:open_filer(dir)
  let app = viler#App#create(s:filer_work_dir)
  return app.create_filer(a:dir)
endfunction

function! s:suite.open_filer_for_specified_dir() abort
  let tree = [
    \   'a',
    \   'b',
    \ ]
  let flist = viler#testutil#Flist#new(tree)
  let ffs = viler#testutil#FlistFs#create()
  call ffs.flist_to_files(s:work_dir, flist)

  let filer = s:open_filer(s:work_dir)
  let buf = filer.buffer()

  let row_count = buf.lnum_last() - buf.lnum_first() + 1
  call s:assert.equals(row_count, 2, 'row count')

  let row = buf.node_row(buf.lnum_last())
  call s:assert.equals([row.name, row.is_dir], ['b', 0])
endfunction
