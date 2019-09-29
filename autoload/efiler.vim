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
endfunction
