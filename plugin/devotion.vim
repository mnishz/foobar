" TODO: Vim global plugin for correcting typing mistakes
" Last Change:  2018/10/22
" Maintainer:   Masato Nishihata
" License:      This file is placed in the public domain.

if exists('g:loaded_devotion')
  finish
endif
let g:loaded_devotion = 1

let s:save_cpo = &cpo
set cpo&vim

" TODO: 年単位くらいでファイルを分ける？
" TODO: 結果表示関数 or コマンドの作成
" TODO: vimの総起動時間もあると比較ができて良さそう
" TODO: release前にdebugを落とす
" すぐに解決するのが難しい問題はTODOとしてGitHubに書いておいてよいかもしれない

" :DevotionRange
" :DevotionToday
" :DevotionLastDay (前日ではなく、最終使用日がいいかも)
" :DevotionThisWeek
" :DevotionLastWeek
" :DevotionThisMonth
" :DevotionLastMonth
" :DevotionThisYear
" :DevotionLastYear

augroup devotion
  autocmd!
  autocmd BufEnter *    if g:devotion#IsTargetFileType() | call g:devotion#BufEnter()    | endif
  autocmd BufLeave *    if g:devotion#IsTargetFileType() | call g:devotion#BufLeave()    | endif
  autocmd BufUnload *   if g:devotion#IsTargetFileType() | call g:devotion#BufUnload()   | endif
  autocmd InsertEnter * if g:devotion#IsTargetFileType() | call g:devotion#InsertEnter() | endif
  autocmd InsertLeave * if g:devotion#IsTargetFileType() | call g:devotion#InsertLeave() | endif
  autocmd FocusLost *   if g:devotion#IsTargetFileType() | call g:devotion#FocusLost()   | endif
  autocmd FocusGained * if g:devotion#IsTargetFileType() | call g:devotion#FocusGained() | endif
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo
