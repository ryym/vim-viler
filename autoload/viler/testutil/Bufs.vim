let s:Bufs = {}

function! viler#testutil#Bufs#new(work_dir) abort
  let bufs = deepcopy(s:Bufs)
  let bufs.work_dir = a:work_dir
  let bufs._id = 0
  let bufs._bufnrs = []
  return bufs
endfunction

function! s:Bufs.reset() abort
  let self._id = 0
  let self._bufnrs = []
endfunction

function! s:Bufs.add(bufnr)
  call add(self._bufnrs, a:bufnr)
endfunction

function! s:Bufs.open() abort
  let self._id += 1
  silent execute 'edit' viler#Path#join(self.work_dir, self._id)
  let bufnr = bufnr('%')
  call add(self._bufnrs, bufnr)
  return bufnr
endfunction

function! s:Bufs.cleanup() abort
  let bufinfo_list = getbufinfo()
  let bufinfo = {}
  for info in bufinfo_list
    let bufinfo[info.bufnr] = info
  endfor

  for bufnr in self._bufnrs
    let path = bufinfo[bufnr].name
    if filereadable(path)
      call delete(path)
    endif
    silent execute 'bwipeout!' bufnr
  endfor
endfunction
