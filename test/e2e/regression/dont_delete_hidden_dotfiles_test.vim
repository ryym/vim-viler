let s:suite = themis#suite('E2E')
let s:assert = themis#helper('assert')
let s:t = viler#testutil#e2e#setup(s:suite)

function! s:suite.regression__dont_delete_hidden_dotfiles() abort
  call s:t.work_dir.make_files([
    \   '.z',
    \   'a',
    \   'b',
    \ ])

  call viler#open(s:t.work_dir.path)
  call s:assert.equals(s:t.displayed_lines(), [s:t.work_dir.path, 'a', 'b'], 'initial lines')

  call viler#toggle_dotfiles()
  let want_lines = [s:t.work_dir.path, '.z', 'a', 'b']
  call s:assert.equals(s:t.displayed_lines(), want_lines, 'lines after dotfiles enabled')

  call viler#toggle_dotfiles()
  let want_lines = [s:t.work_dir.path, 'a', 'b']
  call s:assert.equals(s:t.displayed_lines(), want_lines, 'lines after dotfiles disabled')

  call append('$', '')
  call s:t.write_buffer()

  let ffs = viler#testutil#FlistFs#create()
  let got = ffs.files_to_flist(s:t.work_dir.path)
  call s:assert.equals(got.lines(), ['.z', 'a', 'b'], 'files after dotfiles toggle and save')
endfunction
