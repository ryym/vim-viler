" TODO: Add an indicator for each directory to display the directory is open or not.

syntax match VilerHeaderLine /\v.+\|\|.+$/
  \ contains=VilerFilerMeta
highlight link VilerHeaderLine Comment

syntax match VilerFilerMeta /\v\|\|\d+_\d+/
  \ contained
  \ conceal

syntax match VilerLineFile /\v^\s*[^/]+\s\|.+$/
  \ contains=VilerLineMeta

syntax match VilerLineDir /\v^\s*[^/]+\/\s\|.+$/
  \ contains=VilerLineMeta
highlight link VilerLineDir Directory

syntax match VilerLineMeta /\v\|\d+_\d+_\d$/
  \ contained
  \ conceal
