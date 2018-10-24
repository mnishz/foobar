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
  autocmd BufEnter *    call s:DevotionBufEnter()
  autocmd BufLeave *    call s:DevotionBufLeave()
  autocmd BufUnload *   call s:DevotionBufUnload()
  autocmd InsertEnter * call s:DevotionInsertEnter()
  autocmd InsertLeave * call s:DevotionInsertLeave()
  autocmd FocusGained * call s:DevotionFocusGained()
  autocmd FocusLost *   call s:DevotionFocusLost()
augroup END

" utilities

function! s:IsVimBuffer()
  if getbufvar(str2nr(expand("<abuf>")), "&filetype") ==# "vim"
    return v:true
  else
    return v:false
  endif
endfunction

" autocmd functions

function! s:DevotionBufEnter()
  if !s:IsVimBuffer() | return | endif
  if s:monitoring_status != 0 | echoerr "mntrvims" | call writefile(["BufEnter Status Error", s:monitoring_status], s:log_file_name, "a") | endif
  call writefile(["BufEnter    @ " . localtime() . " for " . expand("<afile>:p")], s:log_file_name, "a")
  let s:monitoring_status = 1
  let s:buf_enter_timestamp = localtime()
  let s:curr_target_file_name = expand("<afile>")
endfunction

function! s:DevotionBufLeave()
  if getbufvar(str2nr(expand("<abuf>")), "&filetype") ==# "vim" && expand("<afile>") ==# s:curr_target_file_name
    if s:monitoring_status != 1 | echoerr "mntrvims" | call writefile(["BufLeave Status Error", s:monitoring_status], s:log_file_name, "a") | endif
    call writefile(["BufLeave    @ " . localtime() . " for " . expand("<afile>:p")], s:log_file_name, "a")
    let s:monitoring_status = 0
    let s:total_buf_enter_time += localtime() - s:buf_enter_timestamp - s:total_focus_lost_time_for_buf_enter
    if s:total_buf_enter_time < 0 | echoerr "mntrvims" | call writefile(["BufLeave Time Error"], s:log_file_name, "a") | endif
    call writefile([strftime("%c") . ", " . s:total_buf_enter_time . " [sec], Viewed " . expand("<afile>:p")], s:result_file_name, "a")
    call writefile(["  [debug] leave: " . localtime() . ", enter: " . s:buf_enter_timestamp . ", focus_lost: " . s:total_focus_lost_time_for_buf_enter], s:result_file_name, "a")
    let s:total_focus_lost_time_for_buf_enter = 0
    let s:total_buf_enter_time = 0
  endif
endfunction

function! s:DevotionBufUnload()
  if getbufvar(str2nr(expand("<abuf>")), "&filetype") ==# "vim" && expand("<afile>") ==# s:curr_target_file_name
    if s:monitoring_status != 0 && s:monitoring_status != 1 | echoerr "mntrvims" | call writefile(["BufUnload Status Error", s:monitoring_status], s:log_file_name, "a") | endif
    if s:monitoring_status == 0
      call writefile(["BufUnload   @ " . localtime() . " for " . expand("<afile>:p") . " (ignored)"], s:log_file_name, "a")
    elseif s:monitoring_status == 1
      call writefile(["BufUnload   @ " . localtime() . " for " . expand("<afile>:p")], s:log_file_name, "a")
      let s:monitoring_status = 0
      let s:total_buf_enter_time += localtime() - s:buf_enter_timestamp - s:total_focus_lost_time_for_buf_enter
      if s:total_buf_enter_time < 0 | echoerr "mntrvims" | call writefile(["BufUnload Time Error"], s:log_file_name, "a") | endif
      call writefile([strftime("%c") . ", " . s:total_buf_enter_time . " [sec], Viewed " . expand("<afile>:p")], s:result_file_name, "a")
      call writefile(["  [debug] leave: " . localtime() . ", enter: " . s:buf_enter_timestamp . ", focus_lost: " . s:total_focus_lost_time_for_buf_enter], s:result_file_name, "a")
      let s:total_focus_lost_time_for_buf_enter = 0
      let s:total_buf_enter_time = 0
      endif
  endif
endfunction

function! s:DevotionInsertEnter()
  if getbufvar(str2nr(expand("<abuf>")), "&filetype") ==# "vim" && expand("<afile>") ==# s:curr_target_file_name
    if s:monitoring_status != 1 | echoerr "mntrvims" | call writefile(["InsertEnter Status Error", s:monitoring_status], s:log_file_name, "a") | endif
    call writefile(["InsertEnter @ " . localtime() . " for " . expand("<afile>:p")], s:log_file_name, "a")
    let s:monitoring_status = 2
    let s:insert_enter_timestamp = localtime()
  endif
endfunction

function! s:DevotionInsertLeave()
  if getbufvar(str2nr(expand("<abuf>")), "&filetype") ==# "vim" && expand("<afile>") ==# s:curr_target_file_name
    if s:monitoring_status != 2 | echoerr "mntrvims" | call writefile(["InsertLeave Status Error", s:monitoring_status], s:log_file_name, "a") | endif
    call writefile(["InsertLeave @ " . localtime() . " for " . expand("<afile>:p")], s:log_file_name, "a")
    let s:monitoring_status = 1
    let s:total_insert_enter_time += localtime() - s:insert_enter_timestamp - s:total_focus_lost_time_for_insert_enter
    if s:total_insert_enter_time < 0 | echoerr "mntrvims" | call writefile(["InsertLeave Time Error"], s:log_file_name, "a") | endif
    call writefile([strftime("%c") . ", " . s:total_insert_enter_time . " [sec], Edited " . expand("<afile>:p")], s:result_file_name, "a")
    call writefile(["  [debug] leave: " . localtime() . ", enter: " . s:insert_enter_timestamp . ", focus_lost: " . s:total_focus_lost_time_for_insert_enter], s:result_file_name, "a")
    let s:total_focus_lost_time_for_insert_enter = 0
    let s:total_insert_enter_time = 0
  endif
endfunction

function! s:DevotionFocusGained()
  if getbufvar(str2nr(expand("<abuf>")), "&filetype") ==# "vim" && expand("<afile>") ==# s:curr_target_file_name
    if s:focus_status != 0 | echoerr "mntrvims" | call writefile(["FocusGained Status Error 1", s:focus_status], s:log_file_name, "a") | endif
    let s:focus_status = 1
    call writefile(["FocusGained @ " . localtime() . " for " . expand("<afile>:p")], s:log_file_name, "a")
    if s:monitoring_status == 1
      let s:total_focus_lost_time_for_buf_enter += localtime() - s:focus_gained_timestamp
      if s:total_focus_lost_time_for_buf_enter < 0 | echoerr "mntrvims" | call writefile(["FocusGained Time Error"], s:log_file_name, "a") | endif
    elseif s:monitoring_status == 2
      let s:total_focus_lost_time_for_buf_enter += localtime() - s:focus_gained_timestamp
      if s:total_focus_lost_time_for_buf_enter < 0 | echoerr "mntrvims" | call writefile(["FocusGained Time Error"], s:log_file_name, "a") | endif
      let s:total_focus_lost_time_for_insert_enter += localtime() - s:focus_gained_timestamp
      if s:total_focus_lost_time_for_insert_enter < 0 | echoerr "mntrvims" | call writefile(["FocusGained Time Error"], s:log_file_name, "a") | endif
    else
      echoerr "mntrvims" | call writefile(["FocusGained Status Error 2", s:monitoring_status], s:log_file_name, "a")
    endif
  endif
endfunction

function! s:DevotionFocusLost()
  if getbufvar(str2nr(expand("<abuf>")), "&filetype") ==# "vim" && expand("<afile>") ==# s:curr_target_file_name
    if s:focus_status != 1 | echoerr "mntrvims" | call writefile(["FocusLost Status Error", s:focus_status], s:log_file_name, "a") | endif
    let s:focus_status = 0
    call writefile(["FocusLost   @ " . localtime() . " for " . expand("<afile>:p")], s:log_file_name, "a")
    let s:focus_gained_timestamp = localtime()
  endif
endfunction

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
