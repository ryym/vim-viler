let s:Fs = {}

" TODO: Do error handling.
" TODO: Add logging.

function! viler#lib#Fs#new() abort
  let fs = deepcopy(s:Fs)
  return fs
endfunction

function! viler#lib#Fs#readdir(...) abort
  " At this time this function does not exist on Neovim.
  if exists('*readdir')
    return call('readdir', a:000)
  endif

  " The order of file names may be different with `readdir`.
  return call('viler#lib#Fs#readdir_by_glob', a:000)
endfunction

function! viler#lib#Fs#readdir_by_glob(...) abort
  let dir = a:000[0]

  let prefix_len = strchars(dir) + 1 " /
  let names = []

  for path in glob(dir . '/.*', 1, 1)
    let name = strcharpart(path, prefix_len)
    if name isnot# '.' && name isnot# '..'
      call add(names, name)
    endif
  endfor
  for path in glob(dir . '/*', 1, 1)
    call add(names, strcharpart(path, prefix_len))
  endfor

  " call g:t.log(len(a:000) > 1 ? filter(names, a:000[1]) : '----')
  return len(a:000) > 1 ? filter(names, a:000[1]) : names
endfunction

function! s:Fs.make_file(path) abort
  call writefile([], a:path)
endfunction

function! s:Fs.make_file_with(path, content) abort
  call writefile(a:content, a:path)
endfunction

function! s:Fs.make_dir(path) abort
  call mkdir(a:path)
endfunction

function! s:Fs.delete_file(path) abort
  call delete(a:path, "rf")
endfunction

function! s:Fs.move_file(src_path, dest_path) abort
  call rename(a:src_path, a:dest_path)
endfunction

function! s:Fs.copy_file(src_path, dest_path) abort
  " TODO: Be cross-platform.
  call system('cp -r ' . shellescape(a:src_path) . ' ' . shellescape(a:dest_path))
endfunction
