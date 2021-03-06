" Flist is an object that mimics the Buffer state for testing.
" You can generate Flist from a list like:
"   [
"     'd1/',
"     '  a/',
"     '    b',
"     '  x',
"     'd2/',
"   ]
" Flist then converts each line to a row with metadata such as a depth,
" whether it is a directory or not, etc.
let s:Flist = {}

function! viler#testutil#Flist#new(lines) abort
  let flist = deepcopy(s:Flist)
  let flist._rows = s:decode_lines(a:lines)
  return flist
endfunction

function! viler#testutil#Flist#from_text(text) abort
  return viler#testutil#Flist#new(split(a:text, '\n'))
endfunction

function! viler#testutil#Flist#from_rows(rows) abort
  let flist = deepcopy(s:Flist)
  let flist._rows = a:rows
  return flist
endfunction

function! s:Flist.len() abort
  return len(self._rows)
endfunction

function! s:Flist.get(lnum) abort
  return self._rows[a:lnum]
endfunction

function! s:Flist.lines() abort
  return map(copy(self._rows), {_, r -> s:row_to_s(r)})
endfunction

function! s:Flist.to_s() abort
  if self.len() is# 0
    return ''
  endif
  return "\n" . join(self.lines(), "\n") . "\n"
endfunction

function! s:Flist.iter() abort
  return s:new_iter(self)
endfunction

function! s:decode_lines(lines) abort
  let rows = []
  let dirs = []
  let prev_name = ''
  let prev_depth = 0
  let lnum = 1

  for line in a:lines
    let row = s:decode_line(lnum, line)
    let row.commit_id = 0 " For now
    call add(rows, row)

    if row.name is# ''
      let lnum += 1
      let row.dir = ''
      continue
    endif

    if row.depth > prev_depth
      call add(dirs, prev_name)
    else
      while row.depth < prev_depth
        let prev_depth -= 1
        let dirs = dirs[0:-2]
      endwhile
    endif

    let lnum += 1
    let prev_depth = row.depth
    let prev_name = row.name
    let row.dir = join(dirs, '/')
  endfor

  return rows
endfunction

function! s:decode_line(lnum, line) abort
  let [indent, line] = viler#lib#Str#split_head_tail(a:line, '\v^\s*')
  let parts = split(line, ' ')

  let is_dir = 0
  let open = 1
  if len(parts) > 0
    let name = parts[0]
    let last = len(name) - 1
    if name[last-1:last] is# '/-'
      let open = 0
      let last -= 1
      let name = name[0:-2]
    endif
    let is_dir = name[last] is# '/'
  else
    let name = ''
  endif

  let row = {
    \   'lnum': a:lnum,
    \   'name': is_dir ? name[0:-2] : name,
    \   'is_dir': is_dir,
    \   'depth': len(indent) / 2,
    \   'is_new': 0,
    \ }

  for part in parts[1:-1]
    if part is# 'is_new'
      let row.is_new = 1
    elseif part[0:4] is# 'from:'
      let row.src_path = part[5:]
    elseif part[0:7] is# 'content:'
      let row.content = part[8:]
    else
      throw '[Flist] Unknown attribute ' . part
    endif
  endfor

  if is_dir
    let row.state = {'tree_open': open}
  endif
  return row
endfunction

function! s:row_to_s(row) abort
  let indent = repeat(' ', a:row.depth * 2)
  let line = indent . a:row.name . (a:row.is_dir ? '/' : '')
  if has_key(a:row, 'content')
    let line .= ' ' . 'content:' . a:row.content
  endif
  return line
endfunction

let s:Iter = {}

function! s:new_iter(flist) abort
  let iter = copy(s:Iter)
  let iter.flist = a:flist
  let iter._lnum = 0
  return iter
endfunction

function! s:Iter.has_next() abort
  return self._lnum < self.flist.len()
endfunction

function! s:Iter.lnum() abort
  return self._lnum
endfunction

function! s:Iter.peek() abort
  return self.flist.get(self._lnum)
endfunction

function! s:Iter.next() abort
  if !self.has_next()
    throw 'Flist iterator is at end'
  endif
  let row = self.peek()
  let self._lnum += 1
  return row
endfunction
