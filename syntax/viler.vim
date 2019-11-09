function! s:main() abort
  syntax match VilerHeaderLine /\v.+\|\|.+$/
    \ contains=VilerFilerMeta
  highlight link VilerHeaderLine Comment

  syntax match VilerFilerMeta /\v\|\|\d+_\d+/
    \ contained
    \ conceal

  syntax match VilerLineFile /\v^\s*[^/]+\s\|.+$/
    \ contains=VilerLineMeta

  syntax match VilerLineDirClosed /\v^\s*\zs[^/]+\/\s\|.+0$/
    \ contains=VilerLineMeta
  highlight link VilerLineDirClosed Directory

  syntax match VilerLineDirOpen /\v^\s*\zs[^/]+\/\s\|.+1$/
    \ contains=VilerLineDirNameOpen,VilerLineMeta
  highlight link VilerLineDirOpen Directory

  syntax match VilerLineDirNameOpen /\v[^/]+\ze\//
    \ contained
  execute 'highlight VilerLineDirNameOpen' s:open_dir_highlight()

  syntax match VilerLineMeta /\v\|\d+_\d+_\d$/
    \ contained
    \ conceal
endfunction

function! s:open_dir_highlight() abort
  redir => dir_hl
  silent highlight Directory
  redir END

  " The value is like 'Directory xxx ctermfg=123 guifg=456...'.
  let dir_hl = substitute(dir_hl, '\n', '', 'g')
  let dir_hl = split(dir_hl, '\s\+')
  let dir_hl = dir_hl[2:]

  return join(dir_hl, ' ') . ' cterm=underline'
endfunction

call s:main()
