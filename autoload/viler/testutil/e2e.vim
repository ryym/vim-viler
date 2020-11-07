let s:E2eTestUtil = {}

function! viler#testutil#e2e#setup(suite) abort
  let s:hooks = g:t.hooks()

  function! s:hooks.before_each.enable_viler()
    " Reset viler#app singleton before each test.
    call viler#enable()
  endfunction

  function! a:suite.before() abort
    " Throw error instead of just showing a message.
    let g:_viler_is_debug = 1
  endfunction

  " Manage buffers to clean up after each test.
  call g:t.use_buffers(s:hooks, { 'auto_add_current_buf': 1 })

  " Create a working directory.
  let work_dir = g:t.use_work_dir(s:hooks)

  call s:hooks.register_to(a:suite)

  let t = copy(s:E2eTestUtil)
  let t.work_dir = work_dir
  return t
endfunction

" Return the file names displayed on the current filer buffer without meta data.
function! s:E2eTestUtil.displayed_lines() abort
  let lines = getline(1, '$')
  return map(lines, { i, l -> substitute(l, '\v\s+(/\||\|).+', '', '') })
endfunction

" Do :write and throw if it fails.
function! s:E2eTestUtil.write_buffer() abort
  let bnr = bufnr('%')

  redir => output
  try
    execute 'write'
  finally
    redir END
  endtry

  if output =~# 'E\d\+'
    call g:t.log(output)
    throw 'buffer write seems failed. See output log.'
  endif
endfunction

" Break the undo sequence.
" To test undo/redo, we need to specify undo breakpoint manually. Otherwise executing 'undo'
" resets all modifications on the buffer since the changes are made by script.
function! s:E2eTestUtil.break_undo_sequence() abort
  call feedkeys("i\<C-g>u", "x")
endfunction
