let s:suite = themis#suite('testutil#Flisttree')
let s:assert = themis#helper('assert')

function! s:suite.iter_empty() abort
  let flist = viler#testutil#Flist#new([])
  let tree = viler#testutil#FlistFiletree#new('', flist)
  let iter = tree.iter()
  call s:assert.equals(iter.has_next(), 0)
endfunction

function! s:suite.iter_flat() abort
  let flist = viler#testutil#Flist#new([
    \   'a',
    \   'b/',
    \   'c/',
    \ ])
  let tree = viler#testutil#FlistFiletree#new('', flist)

  let iter = tree.iter()
  let items = [
    \   [iter.has_next(), iter.next().name],
    \   [iter.has_next(), iter.next().name],
    \   [iter.has_next(), iter.next().name],
    \   [iter.has_next()],
    \ ]

  let want = [[1, 'a'], [1, 'b'], [1, 'c'], [0]]
  call s:assert.equals(items, want)
endfunction

function! s:suite.iter_nested() abort
  let flist = viler#testutil#Flist#new([
    \   'a',
    \   'b/',
    \   '  b-1/',
    \   '    b-1-1',
    \   '    b-1-2/',
    \   'c/',
    \   '  c-1',
    \ ])
  let tree = viler#testutil#FlistFiletree#new('', flist)

  let names = []
  let iter = tree.iter()
  while iter.has_next()
    call add(names, iter.next().name)
  endwhile

  let want = ["a", "b", "b-1", "b-1-1", "b-1-2", "c", "c-1"]
  call s:assert.equals(names, want)
endfunction

