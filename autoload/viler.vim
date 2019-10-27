function! viler#enable() abort
  augroup viler
    autocmd!
    autocmd BufNewFile,BufRead *.viler setfiletype viler
    autocmd BufEnter *.viler call viler#on_buf_enter()
    autocmd BufLeave *.viler call viler#on_buf_leave()
    autocmd BufWriteCmd *.viler call viler#on_buf_save()
  augroup END

  let work_dir = tempname()
  call mkdir(work_dir)
  let s:app = viler#App#create(work_dir)

  command! Viler call viler#open()
endfunction

function! viler#open() abort
  let cur_bufnr = bufnr('%')
  if s:app.has_filer_for(cur_bufnr)
    call s:app.open(cur_bufnr, getcwd())
    return
  endif

  call s:app.create_filer(getcwd())

  setlocal conceallevel=1
  setlocal concealcursor=nvic

  " XXX: Temporary.
  Map n (buffer silent nowait) <C-l> ::call viler#open_cursor_file()
  Map n (buffer silent nowait) <C-h> ::call viler#go_up_dir()
  Map n (buffer silent nowait) <C-j> ::call viler#toggle_tree()
  Map n (buffer silent nowait) u ::call viler#undo()
  Map n (buffer silent nowait) <C-r> ::call viler#redo()
endfunction

function! viler#_debug() abort
  return s:current_filer()
endfunction

function! s:current_filer() abort
  let filer = s:app.filer_for(bufnr('%'))
  if type(filer) == v:t_number
    throw '[viler] This buffer is not a file explorer'
  endif
  return filer
endfunction

function! viler#on_buf_enter() abort
  let filer = s:app.filer_for(bufnr('%'))
  if type(filer) == v:t_number
    return
  endif
  call filer.on_buf_enter()
endfunction

function! viler#on_buf_leave() abort
  call s:current_filer().on_buf_leave()
endfunction

function! viler#on_buf_save() abort
  call s:app.on_any_buf_save()
endfunction

function! viler#open_cursor_file(...) abort
  let cmd = get(a:000, 0, 'wincmd w | drop')
  call s:current_filer().open_cursor_file(cmd)
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
