" A test utility to register multiple same hooks.
" vim-themis does not allow to register a same hook (e.g. before_each) multiple times.
let s:Hooks = {}

let s:hook_names = ['before', 'after', 'before_each', 'after_each']

function! viler#testutil#Hooks#new() abort
  let hooks = deepcopy(s:Hooks)
  for name in s:hook_names
    let hooks[name] = viler#testutil#Hooks#new_hook_set(name)
  endfor
  return hooks
endfunction

function! s:Hooks.register_to(suite) abort
  for name in s:hook_names
    call self[name].__register(a:suite)
  endfor
endfunction

let s:HookSet = {}

function! viler#testutil#Hooks#new_hook_set(name) abort
  let hookSet = deepcopy(s:HookSet)
  let hookSet._name = a:name
  return hookSet
endfunction

function! s:HookSet.__list_funcs() abort
  let fs = []
  for key in keys(self)
    let F = self[key]
    if type(F) == v:t_func && key[0:1] != '__'
      call add(fs, F)
    endif
  endfor
  return fs
endfunction

function! s:HookSet.__register(suite) abort
  let fs = self.__list_funcs()
  if len(fs) > 0
    let a:suite[self._name] = function('s:run_hook_set', [fs, a:suite])
  endif
endfunction

function! s:run_hook_set(fs, suite) abort
  for F in a:fs
    call call(F, [], a:suite)
  endfor
endfunction
