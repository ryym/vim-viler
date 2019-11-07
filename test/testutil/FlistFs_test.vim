let s:suite = themis#suite('testutil#FlistFs')
let s:assert = themis#helper('assert')

function! s:suite.before_each() abort
  let self._work_dir = tempname()
  call mkdir(self._work_dir)
endfunction

function! s:suite.after_each() abort
  call delete(self._work_dir, "rf")
endfunction

function! s:suite.flist_to_files_and_vice_verca() abort
  let lines = [
    \   'hello/',
    \   '  a',
    \   '  b/',
    \   '    foo/',
    \   '  c/',
    \   '    x/',
    \   '      y',
    \   '  d/',
    \ ]
  let flist = viler#testutil#Flist#new(lines)

  let fs = viler#testutil#FlistFs#create()
  call fs.flist_to_files(self._work_dir, flist)

  let file_names = readdir(self._work_dir . '/hello')
  call s:assert.equals(file_names, ['a', 'b', 'c', 'd'])

  let made = fs.files_to_flist(self._work_dir)
  call s:assert.equals(made.to_s(), flist.to_s())
endfunction

function! s:suite.write_specified_content_to_file() abort
  let lines = [
    \   'a/',
    \   '  b content:vim-is-cool',
    \   'c content:hello',
    \ ]
  let flist = viler#testutil#Flist#new(lines)

  let fs = viler#testutil#FlistFs#create()
  call fs.flist_to_files(self._work_dir, flist)

  let b_content = readfile(self._work_dir . '/a/b')
  call s:assert.equals(b_content, ['vim-is-cool'])

  let c_content = readfile(self._work_dir . '/c')
  call s:assert.equals(c_content, ['hello'])

  let made = fs.files_to_flist(self._work_dir)
  call s:assert.equals(made.to_s(), flist.to_s())
endfunction

