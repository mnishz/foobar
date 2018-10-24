" TODO: Vim global plugin for correcting typing mistakes
" Last Change:  2018/10/22
" Maintainer:   Masato Nishihata
" License:      This file is placed in the public domain.

if exists("g:loaded_mntrvims")
  finish
endif
let g:loaded_mntrvims = 1

let s:save_cpo = &cpo
set cpo&vim

" TODO: use XDG_CACHE_HOME?
let s:log_file_name = expand("~/.cache/mntrvims.log")
let s:result_file_name = expand("~/.cache/mntrvims.txt")

let s:curr_target_file_name = ""

" TODO: magic number
let s:monitoring_status = 0 " 0: not monitoring, 1: monitoring, 2: monitoring and insert mode
let s:focus_status = 1

let s:buf_enter_timestamp = 0
let s:total_buf_enter_time = 0

let s:insert_enter_timestamp = 0
let s:total_insert_enter_time = 0

let s:focus_gained_timestamp = 0
let s:total_focus_lost_time_for_buf_enter = 0
let s:total_focus_lost_time_for_insert_enter = 0

" assumption
"
" BufEnter
" |
" | FocusLost
" | |
" | V
" | FocusGained
" |
" | InsertEnter
" | |
" | | FocusLost
" | | |
" | | V
" | | FocusGained
" | V
" | InsertLeave
" V
" BufLeave/BufUnload

" TODO: 各 event の内容を関数化する
" TODO: 共通処理を抜き出す
" TODO: ファイルタイププラグインである必要は？
" TODO: debug 用データの削除
" TODO: Enter での status チェックはないほうがいいかもしれない、取り逃したときのために
" TODO: 結果表示関数 or コマンドの作成
" TODO: vimの総起動時間もあると比較ができて良さそう
" TODO: 日付の出力も strftime() よりは localtime() のほうが検索とか容量とかで
" 見ると better だと思う
" TODO: 経過時間が 0 なら省略
" TODO: 同一ファイルかどうかのチェックも入れる
" TODO: ファイル名があるもののみに絞る
" すぐに解決するのが難しい問題はTODOとしてGitHubに書いておいてよいかもしれない

" vim ファイルを開いて、他のファイルに移動した上で :qa すると
" BufLeave BufUnload の順でイベントが発生する

" filetypeを見るのはだめだ。。<abuf>からバッファの情報を抜き出す必要がある
" これで正解？ getbufvar(str2nr(expand("<abuf>")), "&filetype")

augroup mntrvims
  autocmd!
  autocmd BufEnter *    if getbufvar(str2nr(expand("<abuf>")), "&filetype") ==# "vim"
  autocmd BufEnter *      if s:monitoring_status != 0 | echoerr "mntrvims" | call writefile(["BufEnter Status Error", s:monitoring_status], s:log_file_name, "a") | endif
  autocmd BufEnter *      call writefile(["BufEnter    @ " . localtime() . " for " . expand("<afile>:p")], s:log_file_name, "a")
  autocmd BufEnter *      let s:monitoring_status = 1
  autocmd BufEnter *      let s:buf_enter_timestamp = localtime()
  autocmd BufEnter *      let s:curr_target_file_name = expand("<afile>")
  autocmd BufEnter *    endif
  autocmd BufLeave *    if getbufvar(str2nr(expand("<abuf>")), "&filetype") ==# "vim" && expand("<afile>") ==# s:curr_target_file_name
  autocmd BufLeave *      if s:monitoring_status != 1 | echoerr "mntrvims" | call writefile(["BufLeave Status Error", s:monitoring_status], s:log_file_name, "a") | endif
  autocmd BufLeave *      call writefile(["BufLeave    @ " . localtime() . " for " . expand("<afile>:p")], s:log_file_name, "a")
  autocmd BufLeave *      let s:monitoring_status = 0
  autocmd BufLeave *      let s:total_buf_enter_time += localtime() - s:buf_enter_timestamp - s:total_focus_lost_time_for_buf_enter
  autocmd BufLeave *      if s:total_buf_enter_time < 0 | echoerr "mntrvims" | call writefile(["BufLeave Time Error"], s:log_file_name, "a") | endif
  autocmd BufLeave *      call writefile([strftime("%c") . ", " . s:total_buf_enter_time . " [sec], Viewed " . expand("<afile>:p")], s:result_file_name, "a")
  autocmd BufLeave *      call writefile(["  [debug] leave: " . localtime() . ", enter: " . s:buf_enter_timestamp . ", focus_lost: " . s:total_focus_lost_time_for_buf_enter], s:result_file_name, "a")
  autocmd BufLeave *      let s:total_focus_lost_time_for_buf_enter = 0
  autocmd BufLeave *      let s:total_buf_enter_time = 0
  autocmd BufLeave *    endif
  autocmd BufUnload *   if getbufvar(str2nr(expand("<abuf>")), "&filetype") ==# "vim" && expand("<afile>") ==# s:curr_target_file_name
  autocmd BufUnload *     if s:monitoring_status != 0 && s:monitoring_status != 1 | echoerr "mntrvims" | call writefile(["BufUnload Status Error", s:monitoring_status], s:log_file_name, "a") | endif
  autocmd BufUnload *     if s:monitoring_status == 0
  autocmd BufUnload *       call writefile(["BufUnload   @ " . localtime() . " for " . expand("<afile>:p") . " (ignored)"], s:log_file_name, "a")
  autocmd BufUnload *     elseif s:monitoring_status == 1
  autocmd BufUnload *       call writefile(["BufUnload   @ " . localtime() . " for " . expand("<afile>:p")], s:log_file_name, "a")
  autocmd BufUnload *       let s:monitoring_status = 0
  autocmd BufUnload *       let s:total_buf_enter_time += localtime() - s:buf_enter_timestamp - s:total_focus_lost_time_for_buf_enter
  autocmd BufUnload *       if s:total_buf_enter_time < 0 | echoerr "mntrvims" | call writefile(["BufUnload Time Error"], s:log_file_name, "a") | endif
  autocmd BufUnload *       call writefile([strftime("%c") . ", " . s:total_buf_enter_time . " [sec], Viewed " . expand("<afile>:p")], s:result_file_name, "a")
  autocmd BufUnload *       call writefile(["  [debug] leave: " . localtime() . ", enter: " . s:buf_enter_timestamp . ", focus_lost: " . s:total_focus_lost_time_for_buf_enter], s:result_file_name, "a")
  autocmd BufUnload *       let s:total_focus_lost_time_for_buf_enter = 0
  autocmd BufUnload *       let s:total_buf_enter_time = 0
  autocmd BufUnload *       endif
  autocmd BufUnload *   endif
  autocmd InsertEnter * if getbufvar(str2nr(expand("<abuf>")), "&filetype") ==# "vim" && expand("<afile>") ==# s:curr_target_file_name
  autocmd InsertEnter *   if s:monitoring_status != 1 | echoerr "mntrvims" | call writefile(["InsertEnter Status Error", s:monitoring_status], s:log_file_name, "a") | endif
  autocmd InsertEnter *   call writefile(["InsertEnter @ " . localtime() . " for " . expand("<afile>:p")], s:log_file_name, "a")
  autocmd InsertEnter *   let s:monitoring_status = 2
  autocmd InsertEnter *   let s:insert_enter_timestamp = localtime()
  autocmd InsertEnter * endif
  autocmd InsertLeave * if getbufvar(str2nr(expand("<abuf>")), "&filetype") ==# "vim" && expand("<afile>") ==# s:curr_target_file_name
  autocmd InsertLeave *   if s:monitoring_status != 2 | echoerr "mntrvims" | call writefile(["InsertLeave Status Error", s:monitoring_status], s:log_file_name, "a") | endif
  autocmd InsertLeave *   call writefile(["InsertLeave @ " . localtime() . " for " . expand("<afile>:p")], s:log_file_name, "a")
  autocmd InsertLeave *   let s:monitoring_status = 1
  autocmd InsertLeave *   let s:total_insert_enter_time += localtime() - s:insert_enter_timestamp - s:total_focus_lost_time_for_insert_enter
  autocmd InsertLeave *   if s:total_insert_enter_time < 0 | echoerr "mntrvims" | call writefile(["InsertLeave Time Error"], s:log_file_name, "a") | endif
  autocmd InsertLeave *   call writefile([strftime("%c") . ", " . s:total_insert_enter_time . " [sec], Edited " . expand("<afile>:p")], s:result_file_name, "a")
  autocmd InsertLeave *   call writefile(["  [debug] leave: " . localtime() . ", enter: " . s:insert_enter_timestamp . ", focus_lost: " . s:total_focus_lost_time_for_insert_enter], s:result_file_name, "a")
  autocmd InsertLeave *   let s:total_focus_lost_time_for_insert_enter = 0
  autocmd InsertLeave *   let s:total_insert_enter_time = 0
  autocmd InsertLeave * endif
  autocmd FocusGained * if getbufvar(str2nr(expand("<abuf>")), "&filetype") ==# "vim" && expand("<afile>") ==# s:curr_target_file_name
  autocmd FocusGained *   if s:focus_status != 0 | echoerr "mntrvims" | call writefile(["FocusGained Status Error 1", s:focus_status], s:log_file_name, "a") | endif
  autocmd FocusGained *   let s:focus_status = 1
  autocmd FocusGained *   call writefile(["FocusGained @ " . localtime() . " for " . expand("<afile>:p")], s:log_file_name, "a")
  autocmd FocusGained *   if s:monitoring_status == 1
  autocmd FocusGained *     let s:total_focus_lost_time_for_buf_enter += localtime() - s:focus_gained_timestamp
  autocmd FocusGained *     if s:total_focus_lost_time_for_buf_enter < 0 | echoerr "mntrvims" | call writefile(["FocusGained Time Error"], s:log_file_name, "a") | endif
  autocmd FocusGained *   elseif s:monitoring_status == 2
  autocmd FocusGained *     let s:total_focus_lost_time_for_buf_enter += localtime() - s:focus_gained_timestamp
  autocmd FocusGained *     if s:total_focus_lost_time_for_buf_enter < 0 | echoerr "mntrvims" | call writefile(["FocusGained Time Error"], s:log_file_name, "a") | endif
  autocmd FocusGained *     let s:total_focus_lost_time_for_insert_enter += localtime() - s:focus_gained_timestamp
  autocmd FocusGained *     if s:total_focus_lost_time_for_insert_enter < 0 | echoerr "mntrvims" | call writefile(["FocusGained Time Error"], s:log_file_name, "a") | endif
  autocmd FocusGained *   else
  autocmd FocusGained *     echoerr "mntrvims" | call writefile(["FocusGained Status Error 2", s:monitoring_status], s:log_file_name, "a")
  autocmd FocusGained *   endif
  autocmd FocusGained * endif
  autocmd FocusLost *   if getbufvar(str2nr(expand("<abuf>")), "&filetype") ==# "vim" && expand("<afile>") ==# s:curr_target_file_name
  autocmd FocusLost *     if s:focus_status != 1 | echoerr "mntrvims" | call writefile(["FocusLost Status Error", s:focus_status], s:log_file_name, "a") | endif
  autocmd FocusLost *     let s:focus_status = 0
  autocmd FocusLost *     call writefile(["FocusLost   @ " . localtime() . " for " . expand("<afile>:p")], s:log_file_name, "a")
  autocmd FocusLost *     let s:focus_gained_timestamp = localtime()
  autocmd FocusLost *   endif
augroup END

" 結果は辞書のリストで持つのがいい感じかな
" [
"   {
"     filename: "filename",
"     viewing_time: string or int,
"     editing_time: string or int,
"   },
"   {
"     filename: "filename",
"     viewing_time: string or int,
"     editing_time: string or int,
"   },
" ]
" binary search で first line と last line を決めて、
" ファイルが無かったら list を追加
" その後各数値を増やす -> string ではなくて int のほうがいいだろう
" ファイルの開き方は、ctrlp の mru が参考になるかも

let &cpo = s:save_cpo
unlet s:save_cpo
