let s:suite = themis#suite('Hooks')
let s:assert = themis#helper('assert')

function! s:suite.define_multiple_hooks() abort
  let hooks = viler#testutil#Hooks#new()

  function! hooks.before_each.do_a() abort
    let self.state.a = 1
  endfunction

  function! hooks.before_each.do_b() abort
    let self.state.b = 1
  endfunction

  let dummy_suite = {'state': {}}
  call hooks.register_to(dummy_suite)

  call dummy_suite.before_each()
  call s:assert.equals(dummy_suite.state, {'a': 1, 'b': 1})
endfunction

function! s:suite.__actual_use__() abort
  let suite = themis#suite('actual use')
  let hooks = viler#testutil#Hooks#new()

  let suite._log = []

  function! hooks.before._1() abort
    call add(self._log, 'before')
  endfunction

  function! hooks.after._1() abort
    call add(self._log, 'after')
    let want = ['before', 'before_each', 'testcase', 'after_each', 'after']
    call s:assert.equals(self._log, want)
  endfunction

  function! hooks.before_each._1() abort
    call add(self._log, 'before_each')
  endfunction

  function! hooks.after_each._1() abort
    call add(self._log, 'after_each')
  endfunction

  call hooks.register_to(suite)

  function! suite.check_something() abort
    call add(self._log, 'testcase')
    call s:assert.equals(len(self._log), 3)
  endfunction
endfunction
