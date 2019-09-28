let s:buffer = {'_nr': -1, '_path': ''}

function! efiler#buffer#new(path) abort
  let buf = deepcopy(s:buffer)
  let buf._path = a:path
  return buf
endfunction

function! s:buffer.open() abort
  execute 'silent edit' self._path
  let self._nr = bufnr('%')
  call prop_type_add('file', {'bufnr': self._nr})
endfunction

function! s:buffer.nr() abort
  return self._nr
endfunction

function! s:buffer.modified() abort
  return getbufvar(self._nr, '&modified')
endfunction

function! s:buffer.cursor_line() abort
  return line('.')
endfunction

function! s:buffer.last_lnum() abort
  return line('$')
endfunction

function! s:buffer.get_prop_at(lnum) abort
  let props = prop_list(a:lnum)
  return len(props) == 0 ? 0 : props[0]
endfunction

function s:buffer.name_on_line(lnum, depth) abort
  let line = getbufline(self._nr, a:lnum)[0]
  return line[a:depth * 2:]
endfunction

function! s:buffer.save() abort
  noautocmd silent write
endfunction

function! s:buffer.put_cursor(lnum, col) abort
  call cursor(a:lnum, a:col)
endfunction

function! s:buffer.delete_lines(first, last) abort
  call deletebufline(self._nr, a:first, a:last)
endfunction

function! s:buffer.display_files(files) abort
  let first_line_to_remove = len(a:files) + 1
  let modified_already = self.modified()

  let filenames = map(copy(a:files), {_,f -> f.name})
  call setbufline(self._nr, 1, filenames)
  call deletebufline(self._nr, first_line_to_remove, '$')

  call self._register_props(a:files, 1)

  if !modified_already
    call self.save()
  endif
endfunction

function s:buffer.append_files(lnum, depth, files) abort
  let indent = s:make_indent(a:depth)
  let filenames = map(copy(a:files), {_, f -> indent . f.name})
  call append(a:lnum, filenames)
  call self._register_props(a:files, a:lnum + 1)
endfunction

function! s:buffer._register_props(files, start_line) abort
  let i = -1
  let states = []
  while i < len(a:files) - 1
    let i += 1

    let file = a:files[i]
    call prop_add(
      \   a:start_line + i, 1,
      \   {'type': 'file', 'bufnr': self._nr, 'id': file.id},
      \ )
  endwhile

  return states
endfunction

function! s:make_indent(level) abort
  let s = ''
  let i = 0
  while i < a:level
    let s .= '  '
    let i += 1
  endwhile
  return s
endfunction
