" TODO: Vim global plugin for correcting typing mistakes
" Last Change:  2018/10/22
" Maintainer:   Masato Nishihata
" License:      This file is placed in the public domain.

if exists("g:loaded_devotion")
  finish
endif
let g:loaded_devotion = 1

let s:save_cpo = &cpo
set cpo&vim

let s:DEBUG_MODE = v:true | lockvar! s:DEBUG_MODE

" TODO: use XDG_CACHE_HOME?
" TODO: 年単位くらいでファイルを分ける？
let s:log_file_name = expand("~/.cache/devotion.log")
let s:result_file_name = expand("~/.cache/devotion.txt")

let s:target_file_name = ""

let s:NOT_MONITORING =    0 | lockvar! s:NOT_MONITORING
let s:MONITORING =        1 | lockvar! s:MONITORING
let s:MONITORING_INSERT = 2 | lockvar! s:MONITORING_INSERT

let s:monitoring_status = s:NOT_MONITORING
let s:has_focus = v:true

let s:buf_enter_time = 0
let s:insert_enter_time = 0
let s:focus_lost_time = 0

let s:buf_focus_lost_time = 0
let s:insert_focus_lost_time = 0

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

augroup devotion
  autocmd!
  autocmd BufEnter *    if s:IsVimBuffer() | call s:DevotionBufEnter()    | endif
  autocmd BufLeave *    if s:IsVimBuffer() | call s:DevotionBufLeave()    | endif
  autocmd BufUnload *   if s:IsVimBuffer() | call s:DevotionBufUnload()   | endif
  autocmd InsertEnter * if s:IsVimBuffer() | call s:DevotionInsertEnter() | endif
  autocmd InsertLeave * if s:IsVimBuffer() | call s:DevotionInsertLeave() | endif
  autocmd FocusLost *   if s:IsVimBuffer() | call s:DevotionFocusLost()   | endif
  autocmd FocusGained * if s:IsVimBuffer() | call s:DevotionFocusGained() | endif
augroup END

" utilities

function! s:IsVimBuffer()
  if getbufvar(str2nr(expand("<abuf>")), "&filetype") ==# "vim"
    return v:true
  else
    return v:false
  endif
endfunction

function! s:GetBufferFileName()
  return expand("<afile>:p")
endfunction

function! s:IsTargetFile(buffer_file_name)
  if s:target_file_name ==# a:buffer_file_name
    return v:true
  else
    call s:LogFileError(buffer_file_name)
    return v:false
  endif
endfunction

function! s:CalcElapsedTime(buf_leave_time)
  let l:elapsed_time = a:buf_leave_time - s:buf_enter_time - s:total_focus_lost_time_for_buf_enter
  if l:elapsed_time < 0 | call s:LogTimeError() | endif
  if s:DEBUG_MODE | call writefile(["  debug info, " . s:buf_enter_time . ", " . s:total_focus_lost_time_for_buf_enter], s:result_file_name, "a") | endif
  return l:elapsed_time
endfunction

function! s:ClearBufElapsedParam()
  let s:buf_enter_time = 0
  let s:total_focus_lost_time_for_buf_enter = 0
endfunction

function! s:LogBufElapsedTime(curr_time, elapsed_time, file_name)
  call writefile([a:curr_time . ", " . a:elapsed_time . "sec, Viewed " . a:file_name], s:result_file_name, "a")
endfunction

function! s:CalcInsertElapsedTime(insert_leave_time)
  let l:elapsed_time = a:insert_leave_time - s:insert_enter_time - s:total_focus_lost_time_for_insert_enter
  if l:elapsed_time < 0 | call s:LogTimeError() | endif
  if s:DEBUG_MODE | call writefile(["  debug info, " . s:insert_enter_time . ", " . s:total_focus_lost_time_for_insert_enter], s:result_file_name, "a") | endif
  return l:elapsed_time
endfunction

function! s:ClearInsertElapsedParam()
  let s:insert_enter_time = 0
  let s:total_focus_lost_time_for_insert_enter = 0
endfunction

function! s:LogInsertElapsedTime(curr_time, elapsed_time, file_name)
  call writefile([a:curr_time . ", " . a:elapsed_time . "sec, Edited " . a:file_name], s:result_file_name, "a")
endfunction

" utilities for debug

function! s:LogEventTime(event_name, curr_time, file_name)
  if s:DEBUG_MODE
    call writefile([a:event_name . " @ " . a:curr_time . " for " . a:file_name], s:log_file_name, "a")
  endif
endfunction

function! s:LogFileError(file_name)
  if s:DEBUG_MODE
    echoerr "devotion file error"
    call writefile(["file error, target: " . s:target_file_name . ", actual: " . a:file_name], s:log_file_name, "a")
  endif
endfunction

function! s:LogStatusError()
  if s:DEBUG_MODE
    echoerr "devotion status error"
    call writefile(["status error, monitoring_status: " . s:monitoring_status . ", has_focus: " . s:has_focus], s:log_file_name, "a")
  endif
endfunction

function! s:LogBufLeaveUnloadEvent()
  if s:DEBUG_MODE
    call writefile(["  BufLeave -> BufUnload, ignored"], s:log_file_name, "a")
  endif
endfunction

function! s:LogTimeError()
  if s:DEBUG_MODE
    echoerr "devotion time error"
    call writefile(["time error"], a:log_file_name, "a")
  endif
endfunction

" autocmd functions

function! s:DevotionBufEnter()
  let l:buffer_file_name = s:GetBufferFileName()
  let l:time = localtime()
  call s:LogEventTime("BufEnter", l:time, l:buffer_file_name)

  " continue even if the status is not expected one because this is the beginning of everything
  if s:monitoring_status != s:NOT_MONITORING | call s:LogStatusError() | endif

  let s:monitoring_status = s:MONITORING
  let s:buf_enter_time = l:time
  let s:target_file_name = l:buffer_file_name
endfunction

function! s:DevotionBufLeave()
  let l:buffer_file_name = s:GetBufferFileName()
  let l:time = localtime()
  call s:LogEventTime("BufLeave", l:time, l:buffer_file_name)

  " return in case of error because elapsed time cannot be calculated
  if s:monitoring_status != s:MONITORING | call s:LogStatusError() | return | endif
  if !s:IsTargetFile(l:buffer_file_name) | return | endif

  let s:monitoring_status = s:NOT_MONITORING
  let l:elapsed_time = s:CalcBufElapsedTime(l:time)
  call s:LogBufElapsedTime(l:time, l:elapsed_time, l:buffer_file_name)
  call s:ClearBufElapsedParam()
endfunction

function! s:DevotionBufUnload()
  let l:buffer_file_name = s:GetBufferFileName()
  let l:time = localtime()
  call s:LogEventTime("BufUnload", l:time, l:buffer_file_name)

  " BufLeave -> BufUnload can be happen (e.g. :tabnew -> :qa), just log and return
  if s:monitoring_status == s:NOT_MONITORING | call s:LogBufLeaveUnloadEvent() | return | endif
  " return in case of error because elapsed time cannot be calculated
  if s:monitoring_status != s:MONITORING | call s:LogStatusError() | return | endif
  if !s:IsTargetFile(l:buffer_file_name) | return | endif

  let s:monitoring_status = s:NOT_MONITORING
  let l:elapsed_time = s:CalcBufElapsedTime(l:time)
  call s:LogBufElapsedTime(l:time, l:elapsed_time, l:buffer_file_name)
  call s:ClearBufElapsedParam()
endfunction

function! s:DevotionInsertEnter()
  let l:buffer_file_name = s:GetBufferFileName()
  let l:time = localtime()
  call s:LogEventTime("InsertEnter", l:time, l:buffer_file_name)

  " return in case of error because elapsed time cannot be calculated
  if s:monitoring_status != s:MONITORING | call s:LogStatusError() | return | endif
  if !s:IsTargetFile(l:buffer_file_name) | return | endif

  let s:monitoring_status = s:MONITORING_INSERT
  let s:insert_enter_time = l:time
endfunction

function! s:DevotionInsertLeave()
  let l:buffer_file_name = s:GetBufferFileName()
  let l:time = localtime()
  call s:LogEventTime("InsertLeave", l:time, l:buffer_file_name)

  " return in case of error because elapsed time cannot be calculated
  if s:monitoring_status != s:MONITORING_INSERT | call s:LogStatusError() | return | endif
  if !s:IsTargetFile(l:buffer_file_name) | return | endif

  let s:monitoring_status = s:MONITORING
  let l:elapsed_time = s:CalcInsertElapsedTime(l:time)
  call s:LogInsertElapsedTime(l:time, l:elapsed_time, l:buffer_file_name)
  call s:ClearInsertElapsedParam()
endfunction

function! s:DevotionFocusLost()
  let l:buffer_file_name = s:GetBufferFileName()
  let l:time = localtime()
  call s:LogEventTime("FocusLost", l:time, l:buffer_file_name)

  " return in case of error because elapsed time cannot be calculated
  if !s:IsTargetFile(l:buffer_file_name) | return | endif
  " continue even if the status is not expected one because this is the beginning of FocusLost
  if !s:has_focus | call s:LogStatusError() | endif

  let s:has_focus = v:false
  let s:focus_lost_time = l:time
endfunction

function! s:DevotionFocusGained()
  let l:buffer_file_name = s:GetBufferFileName()
  let l:time = localtime()
  call s:LogEventTime("FocusGained", l:time, l:buffer_file_name)

  " return in case of error because elapsed time cannot be calculated
  if s:has_focus | call s:LogStatusError() | return | endif
  if !s:IsTargetFile(l:buffer_file_name) | return | endif

  if s:monitoring_status == s:MONITORING
    let s:buf_focus_lost_time += l:time() - s:focus_lost_time
  elseif s:monitoring_status == s:MONITORING_INSERT
  else
  endif

  if getbufvar(str2nr(expand("<abuf>")), "&filetype") ==# "vim" && expand("<afile>") ==# s:target_file_name
    if s:focus_status != 0 | echoerr "devotion" | call writefile(["FocusGained Status Error 1", s:focus_status], s:log_file_name, "a") | endif
    let s:focus_status = 1
    call writefile(["FocusGained @ " . localtime() . " for " . expand("<afile>:p")], s:log_file_name, "a")
    if s:monitoring_status == 1
      let s:total_focus_lost_time_for_buf_enter += localtime() - s:focus_gained_timestamp
      if s:total_focus_lost_time_for_buf_enter < 0 | echoerr "devotion" | call writefile(["FocusGained Time Error"], s:log_file_name, "a") | endif
    elseif s:monitoring_status == 2
      let s:total_focus_lost_time_for_buf_enter += localtime() - s:focus_gained_timestamp
      if s:total_focus_lost_time_for_buf_enter < 0 | echoerr "devotion" | call writefile(["FocusGained Time Error"], s:log_file_name, "a") | endif
      let s:total_focus_lost_time_for_insert_enter += localtime() - s:focus_gained_timestamp
      if s:total_focus_lost_time_for_insert_enter < 0 | echoerr "devotion" | call writefile(["FocusGained Time Error"], s:log_file_name, "a") | endif
    else
      echoerr "devotion" | call writefile(["FocusGained Status Error 2", s:monitoring_status], s:log_file_name, "a")
    endif
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
" :DevotionRange
" :DevotionLastDay (前日ではなく、最終使用日がいいかも)
" :DevotionLastWeek

let &cpo = s:save_cpo
unlet s:save_cpo
