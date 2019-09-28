let s:File = {'isdraft': 0}

function! s:File.abs_path() abort
  return self.dir . self.name
endfunction

let s:Factory = {}

function! efiler#File#new_factory(uid) abort
  let factory = deepcopy(s:Factory)
  let factory._uid = a:uid
  return factory
endfunction

function! s:Factory.new_file(dir, name) abort
  let dir = a:dir[len(a:dir) - 1] == '/' ? a:dir : a:dir . '/'
  let abs_path = dir . a:name
  let isdir = isdirectory(abs_path)

  let file = deepcopy(s:File)
  let file.dir = dir
  let file.id = self._uid.get(abs_path)
  let file.name = isdir ? a:name . '/' : a:name
  let file.isdir = isdir
  return file
endfunction

function! s:Factory.new_draft_file(dir, name, opt) abort
  let dir = a:dir[len(a:dir) - 1] == '/' ? a:dir : a:dir . '/'
  let isdir = a:name[len(a:name) - 1] == '/'

  let file = deepcopy(s:File)
  let file.isdraft = 1
  let file.dir = dir
  let file.id = self._uid.draft_id()
  let file.name = isdir ? a:name . '/' : a:name
  let file.isdir = isdir
  return file
endfunction
