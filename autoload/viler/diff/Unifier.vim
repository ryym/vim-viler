let s:Unifier = {}

function! viler#diff#Unifier#new(tree, id_gen, validator) abort
  let unifier = deepcopy(s:Unifier)
  let unifier._tree = a:tree
  let unifier._id_gen = a:id_gen
  let unifier._validator = a:validator
  return unifier
endfunction

function! s:unify_diffs2(diffs) abort
  let [move_or_copies, dels, dirops] = self._merge_internal_data(a:diffs)
  let moves = self._detect_moves2(move_or_copies, dels)

  for mv in moves
    if mv.is_copy
      continue
    endif

    " tree: unify nodes
    " (src の children を dest にやるだけ？)
    " XXX: children も混ざる問題があるんだった。。。。。。。。。。。。。。

    " dirop の登録が move の登録とは別ファイラで行われている場合を考慮する。
    " - F1 : /a/ -> /b/, /b/ -> /c/
    "   F1 : edit /b/ (e1)
    "   F1 : edit /c/ (e2)
    " - F2 : edit /b/
    "   F2 : edit /b/ (e3)
    " この場合 F2 の変更は最終的には /c/ となるディレクトリに対して行われるべき。
    " また move の場合、同じファイラ内で src への変更を登録する事はできない。
    " もし src (と同じパス) への登録がある場合、それは別の move の dest のはず。
    " 以下のようにすれば、 e1 は /b/ に、 e2, e3 は /c/ に登録されるはず。

    let maybe_src_ops = dirops[mv.src_id]
    let src_ops = maybe_src_ops->copy()->filter('v:val.filer != mv.filer')

    let maybe_dest_ops = dirops[mv.dest_id]
    let dest_ops = maybe_dest_ops->copy()->filter('v:val.filer == mv.filer')

    " で src_ops を dest への ops にする。
  endfor

  let diff = self._gen_final_diff(moves, dels, dirops)
endfunction

function! s:Unifier._merge_internal_data(diffs) abort
  let moves = []
  let deletions = {}
  let dirops = {}

  for diff in a:diffs
    for move in values(diff.moves)
      let move.filer_id = diff.filer_id
      call add(moves, move)
    endfor

    for id in keys(diff.deletions)
      let deletions[id] = diff.deletions[id]
    endfor

    for id in keys(diff.dirops)
      if !has_key(dirops, id)
        let dirops[id] = []
      endif
      let op = diff.dirops[id]
      let op.filer_id = diff.filer_id
      call add(dirops[id], op)
    endfor
  endfor

  return [moves, deletions, dirops]
endfunction

function! s:Unifier._detect_moves2(entries, deletions) abort
  let moves = []
  for move in a:entries
    if !has_key(a:deletions, move.src_id)
      let move.is_copy = 1
      continue
    endif
    let src = self._tree.get_node(move.src_id)
    let src_parent = self._tree.get_node(src.parent)

    " TODO: これどこでやる？
    " let op = a:diff.dirop(src_parent.id)
    " call remove(op.delete, move.src_id)

    call remove(a:deletions, move.src_id)
    call add(moves, move)
  endfor
  return moves
endfunction

" ---------------------------------------------

function! s:Unifier.unify_diffs(diffs) abort
  let diff = self._merge_diffs(a:diffs)

  let g:_hoge = deepcopy(diff)

  let errs = self._validator.validate_copies(diff.moves)
  if len(errs) > 0
    return { 'error': errs }
  endif

  let moves = self._detect_moves(diff)
  for mv in moves
    call diff.unify_nodes_for_move(mv.src_id, mv.dest_id)
  endfor

  let errs = self._validator.validate_dirs(diff)
  if len(errs) > 0
    return { 'error': errs }
  endif

  return { 'ok': diff }
endfunction

function! s:Unifier._merge_diffs(diffs) abort
  let diff = viler#diff#Diff#new(self._tree, self._id_gen)
  for d in a:diffs
    call diff.merge(d)
  endfor
  return diff
endfunction

function! s:Unifier._detect_moves(diff) abort
  let moves = []
  for move in values(a:diff.moves)
    if !has_key(a:diff.deletions, move.src_id)
      let move.is_copy = 1
      continue
    endif
    let src = self._tree.get_node(move.src_id)
    let src_parent = self._tree.get_node(src.parent)
    let op = a:diff.dirop(src_parent.id)
    call remove(op.delete, move.src_id)
    call remove(a:diff.deletions, move.src_id)
    call add(moves, move)
  endfor
  return moves
endfunction
