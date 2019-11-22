let s:suite = themis#suite('lib#Fs')
let s:assert = themis#helper('assert')

function! s:suite.before_each() abort
  let self._work_dir = tempname()
  call mkdir(self._work_dir)
endfunction

function! s:suite.after_each() abort
  call delete(self._work_dir, "rf")
endfunction

function! s:prepare_files(dir, lines) abort
  let flist = viler#testutil#Flist#new(a:lines)
  let fs = viler#testutil#FlistFs#create()
  call fs.flist_to_files(a:dir, flist)
endfunction

" Assert that the given lists has exactly same values but in any order.
function! s:assert_equal_lists_in_any_order(got, want) abort
  call s:assert.equals(sort(a:got), sort(a:want))
endfunction

function! s:suite.readdir_by_glob_returns_file_names() abort
  call s:prepare_files(self._work_dir, [
    \   'a',
    \   'b/',
    \   '  foo/',
    \   'c/',
    \   'd',
    \ ])
  let names = viler#lib#Fs#readdir_by_glob(self._work_dir)
  let want = ['a', 'b', 'c', 'd']
  call s:assert_equal_lists_in_any_order(names, want)
endfunction

function! s:suite.readdir_by_glob_includes_dotfiles() abort
  call s:prepare_files(self._work_dir, [
    \   '_a',
    \   '.gitignore',
    \   '.git/',
    \   '  foo/',
    \   '..double',
    \   'd/',
    \ ])
  let names = viler#lib#Fs#readdir_by_glob(self._work_dir)
  let want = ['..double', '.git', '.gitignore', 'd', '_a']
  call s:assert_equal_lists_in_any_order(names, want)
endfunction

function! s:suite.readdir_by_glob_filter() abort
  call s:prepare_files(self._work_dir, [
    \   'app',
    \   'config',
    \   'dist',
    \   'views',
    \   'z',
    \ ])
  let names = viler#lib#Fs#readdir_by_glob(
    \   self._work_dir,
    \   {_idx, name -> len(name) <=# 4}
    \ )
  let want = ['app', 'dist', 'z']
  call s:assert_equal_lists_in_any_order(names, want)
endfunction
