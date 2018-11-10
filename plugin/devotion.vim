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

scriptencoding utf-8

" TODO: 年単位くらいでファイルを分ける？
" TODO: 読み込みのほうは後でどうにでもなるけど、書き込みのほうは何かしらできて
" いないといけない気がする。
" TODO: 結果表示関数 or コマンドの作成
" TODO: vimの総起動時間もあると比較ができて良さそう
" TODO: release前にdebugを落とす
" すぐに解決するのが難しい問題はTODOとしてGitHubに書いておいてよいかもしれない

" 日本語は下のほうにあると書いて、英語 -> 日本語の順に書く
" pure Vim script
" 不自然な言葉遣いや表現があったら教えてね

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

command! -nargs=+ DevotionRange call g:devotion#Range(<f-args>)
command! DevotionToday     call g:devotion#Today()
command! DevotionLastDay   call g:devotion#LastDay()
command! DevotionThisWeek  call g:devotion#ThisWeek()
command! DevotionLastWeek  call g:devotion#LastWeek()
command! DevotionThisMonth call g:devotion#ThisMonth()
command! DevotionLastMonth call g:devotion#LastMonth()
command! DevotionThisYear  call g:devotion#ThisYear()
command! DevotionLastYear  call g:devotion#LastYear()

let &cpo = s:save_cpo
unlet s:save_cpo
