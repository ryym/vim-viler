function! viler#enable() abort
  augroup viler
    autocmd!
    autocmd BufNewFile,BufRead *.viler setfiletype viler
    autocmd BufWritePre *.viler call viler#apply_changes()
  augroup END

  let work_dir = tempname()
  call mkdir(work_dir)
  let s:viler = viler#App#create(work_dir)

  command! Viler call viler#open()
endfunction

function! viler#open() abort
  let cur_bufnr = bufnr('%')
  if s:viler.has_filer_for(cur_bufnr)
    call s:viler.open(cur_bufnr, getcwd())
    return
  endif

  call s:viler.create_filer(getcwd())

  setlocal conceallevel=0 " XXX: For debag.
  setlocal concealcursor=nvic

  " XXX: Temporary.
  Map n (buffer silent nowait) <C-l> ::call viler#go_down_cursor_dir()
  Map n (buffer silent nowait) <C-h> ::call viler#go_up_dir()
  Map n (buffer silent nowait) K ::call viler#toggle_tree()
  Map n (buffer silent nowait) u ::call viler#undo()
  Map n (buffer silent nowait) <C-r> ::call viler#redo()
endfunction

function! viler#_debug() abort
  return s:current_filer()
endfunction

function! s:current_filer() abort
  let filer = s:viler.filer_for(bufnr('%'))
  if type(filer) == v:t_number
    throw '[viler] This buffer is not a file explorer'
  endif
  return filer
endfunction

function! viler#go_down_cursor_dir() abort
  call s:current_filer().go_down_cursor_dir()
endfunction

function! viler#go_up_dir() abort
  call s:current_filer().go_up_dir()
endfunction

function! viler#toggle_tree() abort
  call s:current_filer().toggle_tree()
endfunction

function! viler#undo() abort
  call s:current_filer().undo()
endfunction

function! viler#redo() abort
  call s:current_filer().redo()
endfunction

function! viler#apply_changes() abort
  try
    call s:viler.apply_changes()
    call viler#open()
  catch
    " Rethrow the caught exception to:
    " - avoid printing the stack trace (function names)
    " - be sure to abort BufWrite on unexpected errors (e.g. unknown function).
    throw v:exception
  endtry
endfunction
