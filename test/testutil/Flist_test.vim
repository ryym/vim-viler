let s:suite = themis#suite('testutil#FlistFs')
let s:assert = themis#helper('assert')

function! s:suite.reject_unknown_attributes() abort
  let lines = [
    \   'a is_new',
    \   'b hey',
    \ ]

  let errmsg = ''
  try
    let flist = viler#testutil#Flist#new(lines)
  catch /hey/
    let errmsg = v:exception
  endtry

  call s:assert.not_empty(errmsg, 'thrown error message')
endfunction
