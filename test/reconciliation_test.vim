let s:suite = themis#suite('Reconciliation')
let s:assert = themis#helper('assert')

" Currently we depends on tomljson binary.
" (https://github.com/pelletier/go-toml)
let s:tomljson_exe = exists('$TOMLJSON_PATH') ? $TOMLJSON_PATH : 'tomljson'

let s:here = expand('<sfile>:h')
let s:fixtures_root = s:here . '/reconciliation/'
let s:work_dir = tempname()

function! s:suite.before() abort
  if isdirectory(s:work_dir)
    call delete(s:work_dir, "rf")
  endif
  call mkdir(s:work_dir)
endfunction

function! s:suite.after() abort
  call delete(s:work_dir, "rf")
endfunction

function! s:suite.__table__() abort
  let suite = themis#suite('table')

  let names = readdir(s:fixtures_root)
  let confs = []
  for name in names
    let name = fnamemodify(name, ':r')
    let work_dir = s:work_dir . '/' . name
    let conf = s:load_fixtures(s:fixtures_root, name, work_dir)
    call add(confs, conf)
  endfor

  " Define reconciliation test cases dynamically from fixtures.
  for conf in confs
    let suite[conf.name] = funcref('s:reconcile_test', [conf])
  endfor
endfunction

function! s:reconcile_test(conf) abort
  call mkdir(a:conf.work_dir)

  let ffs = viler#testutil#FlistFs#create()

  " Create actual file tree.
  call ffs.flist_to_files(a:conf.work_dir, a:conf.before)

  " Apply reconciliation with mock drafts.
  let id_gen = viler#IdGen#new()
  let reconciler = viler#Reconciler#new(id_gen, s:work_dir . '/__' . a:conf.name)
  call reconciler.reconcile(0, a:conf.drafts)

  " Confirm the result file tree is same as expected.
  let got = ffs.files_to_flist(a:conf.work_dir)
  call s:assert.equals(got.to_s(), a:conf.after.to_s())
endfunction

function! s:load_fixtures(root, name, work_path) abort
  let conf = s:load_toml_as_json(a:root . a:name . '.toml')

  let flist_before = viler#testutil#Flist#from_text(conf.before)
  let flist_after = viler#testutil#Flist#from_text(conf.after)

  let drafts = []
  for draft in conf.draft
    let flist = viler#testutil#Flist#new(split(draft.tree, '\n'))
    let draft_root = viler#Path#join(a:work_path, draft.at)
    let mock_tree = viler#testutil#FlistFiletree#new(draft_root, flist)
    call add(drafts, viler#Draft#new(0, mock_tree))
  endfor

  return {
    \   'name': a:name,
    \   'work_dir': a:work_path,
    \   'before': flist_before,
    \   'after': flist_after,
    \   'drafts': drafts,
    \ }
endfunction

function! s:load_toml_as_json(path) abort
  let json_str = system(s:tomljson_exe . ' ' . a:path)
  return json_decode(json_str)
endfunction
