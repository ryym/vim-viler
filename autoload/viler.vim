" TODO: Remove (or disable).
let g:_viler_is_debug = 0

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
endfunction

function! viler#open(...) abort
  let dir = s:normalize_dir(get(a:000, 0, ''))
  let opt = get(a:000, 1, {})

  if has_key(opt, 'do_before')
    execute 'silent' opt.do_before
  endif

  call s:app.create_filer(dir)

  setlocal conceallevel=2
  setlocal concealcursor=nvic
  setlocal nospell
  setlocal noswapfile
  setlocal nowrap

  " Currently tab width is fixed.
  setlocal tabstop=2
  setlocal shiftwidth=2
  setlocal softtabstop=2
  setlocal expandtab

  if g:_viler_is_debug
    setlocal conceallevel=0
  else
    setlocal bufhidden=hide
    setlocal nobuflisted
  endif

  call s:define_default_key_mappings()
endfunction

function! s:normalize_dir(dir) abort
  return viler#Path#trim_slash(fnamemodify(a:dir, ':p'))
endfunction

function! s:define_default_key_mappings() abort
  " TODO: Allow to disable.
  nmap <buffer> <silent> <nowait> u <Plug>(viler-undo)
  nmap <buffer> <silent> <nowait> <C-r> <Plug>(viler-redo)
endfunction

" For debugging.
function! viler#_app() abort
  return s:app
endfunction

function! s:current_filer() abort
  let filer = s:app.filer_for(bufnr('%'))
  if type(filer) is# v:t_number
    throw '[viler] This buffer is not a file explorer'
  endif
  return filer
endfunction

function! viler#on_buf_enter() abort
  let filer = s:app.filer_for(bufnr('%'))
  if type(filer) is# v:t_number
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

function! viler#refresh() abort
  call s:current_filer().refresh()
endfunction

function! viler#toggle_dotfiles() abort
  let filer = s:current_filer()
  let conf = filer.config()
  call filer.modify_config({'show_dotfiles': !conf.show_dotfiles})
  call filer.refresh()
endfunction

function! viler#delete_old_backups() abort
  let backup_period_days = 14
  let work_dir = viler#App#reconciliation_work_dir()
  let date_secs = 60 * 60 * 24
  let now = localtime()

  let fs = viler#lib#Fs#new()
  for dir in viler#lib#Fs#readdir(work_dir)
    let creation_time = str2nr(dir)
    if creation_time == 0
      continue " Unknown directory.
    endif
    let days_elapsed = (now - creation_time) / date_secs
    if days_elapsed > backup_period_days
      call fs.delete_file(viler#Path#join(work_dir, dir))
    endif
  endfor
endfunction
