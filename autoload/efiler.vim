let s:repo_root = expand('<sfile>:p:h:h')

function! efiler#enable() abort
  augroup efiler
    autocmd!

    autocmd BufNewFile,BufRead *.efiler setfiletype efiler
    " TODO: Set text props on BufRead.
    " The props disappear when a buffer is reloaded.
  augroup END

  command! Efiler call efiler#open()
endfunction

function! efiler#open() abort
  let sample_file = s:repo_root . '/sample.efiler'
  if !filereadable(sample_file)
    call writefile([], sample_file)
  endif

  let buf = efiler#Buffer#new(sample_file)
  let uid = efiler#Uid#new()
  let file_factory = efiler#File#new_factory(uid)
  let filer = efiler#Filer#new(buf, file_factory)

  call buf.open()
  call s:define_key_bindings(buf.nr())

  call filer.display(getcwd())
  call setbufvar(buf.nr(), '_efiler_filer', filer)

  " XXX: For debug.
  let g:_efs = filer._states
  let g:_efd = filer._drafts
endfunction

function s:define_key_bindings(bufnr) abort
  Map n (buffer silent nowait) f ::call efiler#toggle_tree()
  Map n (buffer silent nowait) < ::call efiler#go_up_dir()
  Map n (buffer silent nowait) > ::call efiler#go_down_dir()
endfunction

function! s:get_efiler_inst() abort
  let filer = getbufvar('%', '_efiler_filer', 0)
  if type(filer) == v:t_number
    throw '[efiler] no Efiler found'
  endif
  return filer
endfunction

function! efiler#toggle_tree() abort
  let filer = s:get_efiler_inst()
  call filer.toggle_tree()
endfunction

function! efiler#go_up_dir() abort
  let filer = s:get_efiler_inst()
  call filer.go_up_dir()
endfunction

function! efiler#go_down_dir() abort
  let filer = s:get_efiler_inst()
  call filer.go_down_dir()
endfunction
