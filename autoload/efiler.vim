function! efiler#enable() abort
  augroup efiler
    autocmd!
    autocmd BufNewFile,BufRead *.efiler setfiletype efiler
    autocmd BufWritePre *.efiler call efiler#apply_changes()
  augroup END

  let work_dir = tempname()
  call mkdir(work_dir)
  let s:efiler = efiler#Efiler#create(work_dir)

  command! Efiler call efiler#open()
endfunction

function! efiler#open() abort
  let cur_bufnr = bufnr('%')
  if s:efiler.has_filer_for(cur_bufnr)
    call s:efiler.open(cur_bufnr, getcwd())
    return
  endif

  call s:efiler.create_filer(getcwd())

  setlocal conceallevel=0 " XXX: For debag.
  setlocal concealcursor=nvic

  " XXX: Temporary.
  Map n (buffer silent nowait) <C-l> ::call efiler#go_down_cursor_dir()
  Map n (buffer silent nowait) <C-h> ::call efiler#go_up_dir()
  Map n (buffer silent nowait) f ::call efiler#toggle_tree()
  Map n (buffer silent nowait) u ::call efiler#undo()
  Map n (buffer silent nowait) <C-r> ::call efiler#redo()
endfunction

function! efiler#_debug() abort
  return s:current_filer()
endfunction

function! s:current_filer() abort
  let filer = s:efiler.filer_for(bufnr('%'))
  if type(filer) == v:t_number
    throw '[efiler] This buffer is not a file explorer'
  endif
  return filer
endfunction

function! efiler#go_down_cursor_dir() abort
  call s:current_filer().go_down_cursor_dir()
endfunction

function! efiler#go_up_dir() abort
  call s:current_filer().go_up_dir()
endfunction

function! efiler#toggle_tree() abort
  call s:current_filer().toggle_tree()
endfunction

function! efiler#undo() abort
  call s:current_filer().undo()
endfunction

function! efiler#redo() abort
  call s:current_filer().redo()
endfunction

function! efiler#apply_changes() abort
  try
    call s:efiler.apply_changes()
    call efiler#open()
  catch
    " Rethrow the caught exception to:
    " - avoid printing the stack trace (function names)
    " - be sure to abort BufWrite on unexpected errors (e.g. unknown function).
    throw '[efiler] ' . v:exception
  endtry
endfunction
