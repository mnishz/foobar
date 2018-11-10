scriptencoding utf-8

" variables

let s:devotion_dir = empty($XDG_DATA_HOME) ? '~/.local/share' : $XDG_DATA_HOME
let s:devotion_dir = expand(s:devotion_dir . '/devotion/')
if !isdirectory(s:devotion_dir) | call mkdir(s:devotion_dir, 'p') | endif

let g:devotion#log_file = expand(s:devotion_dir . 'devotion.log')
let g:devotion#debug_enabled = v:true  " TODO
let g:devotion#debug_file = expand(s:devotion_dir . 'debug.log')

let g:devotion#view_timer_ = g:devotion#timer#Timer.New('view')
let g:devotion#edit_timer_ = g:devotion#timer#Timer.New('edit')

" utilities

function! g:devotion#GetEventBufferFileName()
  return expand('<afile>:p')
endfunction

function! g:devotion#GetEventBufferFileType()
  return getbufvar(str2nr(expand('<abuf>')), '&filetype')
endfunction

function! g:devotion#IsTargetFileType() abort
  let l:filetype = devotion#GetEventBufferFileType()
  if (l:filetype ==# 'vim') || (l:filetype ==# 'help')
    return v:true
  else
    return v:false
  endif
endfunction

" command functions to display xxx

function! g:devotion#DevotionRange(start_time, stop_time) abort
  echo 'You devoted your following time to Vim between '
  echon a:start_time[0:3] . '/' . a:start_time[4:5] . '/' . a:start_time[6:7] . ' '
  echon a:start_time[8:9] . ':' . a:start_time[10:11] . ':' . a:start_time[12:13] . ' and '
  echon a:stop_time[0:3] . '/' . a:stop_time[4:5] . '/' . a:stop_time[6:7] . ' '
  echon a:stop_time[8:9] . ':' . a:stop_time[10:11] . ':' . a:stop_time[12:13] . ".\n\n"
  let l:data = g:devotion#log#Log.AddUpElapsedTime(a:start_time, a:stop_time)
  for entry in l:data
    " echo '  Viewed: ' . string(entry.view) . ' sec, Edited: ' . string(entry.edit) . ' sec, File: ' . entry.file . ', filetype: ' . entry.filetype
    echo entry.file . ' (filetype: ' . entry.filetype . ')'
    echo '  Viewed: ' . string(entry.view)
    echo '  Edited: ' . string(entry.edit)
  endfor
endfunction

function! g:devotion#DevotionToday() abort
  let l:today = localtime()
  let l:tomorrow = l:today + (60 * 60 * 24)
  let l:today = eval(strftime('%Y%m%d000000', l:today))
  let l:tomorrow = eval(strftime('%Y%m%d000000', l:tomorrow))
  call g:devotion#DevotionRange(l:today, l:tomorrow)
endfunction

" autocmd functions
"
" view_timer_  autocmd event       edit_timer_
"
" Initialize   BufEnter            Initialize
" Start
"  |
" Suspend      FocusLost
"  *
" Restart      FocusGained
"  |
" Stop         InsertEnter         Start
"                                   |
"              FocusLost           Suspend
"                                   *
"              FocusGained         Restart
"                                   |
" Start        EnsertLeave         Stop
"  |
" Stop         BufLeave/BufUnload

function! g:devotion#BufEnter() abort
  call g:devotion#log#Log.LogAutocmdEvent('BufEnter   ')
  call g:devotion#view_timer_.Initialize(devotion#GetEventBufferFileName())
  call g:devotion#view_timer_.Start()
  call g:devotion#edit_timer_.Initialize(devotion#GetEventBufferFileName())
endfunction

function! g:devotion#BufLeave() abort
  call g:devotion#log#Log.LogAutocmdEvent('BufLeave   ')
  call g:devotion#view_timer_.Stop()
  call g:devotion#log#Log.LogElapsedTime(g:devotion#view_timer_)
  call g:devotion#log#Log.LogElapsedTime(g:devotion#edit_timer_)
  call g:devotion#view_timer_.Clear()
  call g:devotion#edit_timer_.Clear()
endfunction

function! g:devotion#BufUnload() abort
  call g:devotion#log#Log.LogAutocmdEvent('BufUnload  ')
  " each case can happen, BufUnload might be a little irregular
  "   BufEnter -> BufLeave -> BufUnload
  "   BufEnter -> BufUnload for the target file
  "   BufEnter -> BufUnload for another file -> BufUnload for the target file
  " just check the file name
  if g:devotion#view_timer_.IsSameFileName()
    call g:devotion#view_timer_.Stop()
    call g:devotion#log#Log.LogElapsedTime(g:devotion#view_timer_)
    call g:devotion#view_timer_.Clear()
  endif
  if g:devotion#edit_timer_.IsSameFileName()
    call g:devotion#log#Log.LogElapsedTime(g:devotion#edit_timer_)
    call g:devotion#edit_timer_.Clear()
  endif
endfunction

function! g:devotion#InsertEnter() abort
  call g:devotion#log#Log.LogAutocmdEvent('InsertEnter')
  call g:devotion#view_timer_.Stop()
  call g:devotion#edit_timer_.Start()
endfunction

function! g:devotion#InsertLeave() abort
  call g:devotion#log#Log.LogAutocmdEvent('InsertLeave')
  call g:devotion#view_timer_.Start()
  call g:devotion#edit_timer_.Stop()
endfunction

function! g:devotion#FocusLost() abort
  call g:devotion#log#Log.LogAutocmdEvent('FocusLost  ')
  call g:devotion#view_timer_.SuspendIfNeeded()
  call g:devotion#edit_timer_.SuspendIfNeeded()
endfunction

function! g:devotion#FocusGained() abort
  call g:devotion#log#Log.LogAutocmdEvent('FocusGained')
  call g:devotion#view_timer_.RestartIfNeeded()
  call g:devotion#edit_timer_.RestartIfNeeded()
endfunction
