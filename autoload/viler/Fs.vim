let s:Fs = {}

" TODO: Do error handling.
" TODO: Add logging.

function! viler#Fs#new() abort
  let fs = deepcopy(s:Fs)
  return fs
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
