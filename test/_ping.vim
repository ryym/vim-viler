let s:suite = themis#suite('Ping')
let s:assert = themis#helper('assert')

function! s:suite.hello_world()
  call s:assert.equals(1 + 2, 3)
endfunction

function! s:suite.use_some_vim_commands()
  enew!
  call setline(1, ['a', 'b', 'c'])
  call s:assert.equals(getline(1, 5), ['a', 'b', 'c'])
  undo
  call s:assert.equals(getline(1, 5), [''])
endfunction
