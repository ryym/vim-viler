let s:Fs = {}

function! viler#applier#Fs#new() abort
  let fs = deepcopy(s:Fs)
  return fs
endfunction

function! s:Fs.make_file(path) abort
  echom 'touch' a:path
endfunction

function! s:Fs.make_dir(path) abort
  echom 'mkdir' a:path
endfunction

function! s:Fs.delete_file(path) abort
  echom 'rm -rf' a:path
endfunction

function! s:Fs.move_file(src_path, dest_path) abort
  echom 'mv' a:src_path a:dest_path
endfunction

function! s:Fs.copy_file(src_path, dest_path) abort
  echom 'cp -r' a:src_path a:dest_path
endfunction
