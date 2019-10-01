function! efiler#enable() abort
  augroup efiler
    autocmd!
    autocmd BufNewFile,BufRead *.efiler setfiletype efiler
  augroup END

  let s:efiler = efiler#Efiler#create()

  command! Efiler call efiler#open()
endfunction

function! efiler#open() abort
  call s:efiler.open_new(getcwd())

  setlocal conceallevel=0 " XXX: For debag.
  setlocal concealcursor=nvic

  " XXX: Temporary.
  Map n (buffer silent nowait) <C-l> ::call efiler#go_down_cursor_dir()
  Map n (buffer silent nowait) <C-h> ::call efiler#go_up_dir()
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

function! efiler#undo() abort
  call s:current_filer().undo()
endfunction

function! efiler#redo() abort
  call s:current_filer().redo()
endfunction
