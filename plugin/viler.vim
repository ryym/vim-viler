
" Key mappings.
nnoremap <silent> <Plug>(viler-undo) :<C-u>call viler#undo()<CR>
nnoremap <silent> <Plug>(viler-redo) :<C-u>call viler#redo()<CR>
nnoremap <silent> <Plug>(viler-open-file) :<C-u>call viler#open_cursor_file()<CR>
nnoremap <silent> <Plug>(viler-cd-up) :<C-u>call viler#go_up_dir()<CR>
nnoremap <silent> <Plug>(viler-toggle-tree) :<C-u>call viler#toggle_tree()<CR>
nnoremap <silent> <Plug>(viler-toggle-dotfiles) :<C-u>call viler#toggle_dotfiles()<CR>
nnoremap <silent> <Plug>(viler-refresh) :<C-u>call viler#refresh()<CR>

call viler#enable()
