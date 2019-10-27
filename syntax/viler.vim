function! s:main() abort
  syntax match VilerHeaderLine /\v^\|\|.+/
    \ contains=VilerFilerMeta
  highlight link VilerHeaderLine Comment

  syntax match VilerFilerMeta /\v\|\|\d+_\d+/
    \ contained
    \ conceal

  syntax match VilerLineFile /\v^\s*\|\d.+\s*$/
    \ contains=VilerLineMetaFile

  syntax match VilerLineDir /\v^\s*\|\d.+\/\s*$/
    \ contains=VilerLineMetaDirClosed,VilerLineMetaDirOpen
  highlight link VilerLineDir Directory

  syntax match VilerLineMetaDirClosed /\v^\s*\zs\|\d+_\d+_0/
    \ contained
    \ conceal cchar=▸
  highlight link VilerLineMetaDirClosed Comment

  syntax match VilerLineMetaDirOpen /\v^\s*\zs\|\d+_\d+_1/
    \ contained
    \ conceal cchar=▾
  highlight link VilerLineMetaDirOpen Comment

  syntax match VilerLineMetaFile /\v^\s*\zs\|\d+_\d+_2/
    \ contained
    \ conceal
  highlight link VilerLineMetaFile Comment

  call s:weaken_conceal_highlight()
endfunction

" The default color of conceal char is too light I think.
function! s:weaken_conceal_highlight() abort
  redir => comment_colors
  silent highlight Comment
  redir END

  " The value is like 'Comment xxx ctermfg=123 guifg=456...'.
  let comment_colors = substitute(comment_colors, '\n', '', 'g')
  let comment_colors = split(comment_colors, '\s\+')
  let comment_colors = comment_colors[2:]

  " Using link for Conceal does not work so we need to define colors explicitly.
  " FIXME: This affects globally. It should change the color of only Viler filers.
  execute 'highlight Conceal ctermbg=NONE guibg=NONE' join(comment_colors, ' ')
endfunction

call s:main()
