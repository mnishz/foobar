" variables
let s:devotion_dir = empty($XDG_DATA_HOME) ? '~/.local/share' : $XDG_DATA_HOME
let s:devotion_dir = expand(s:devotion_dir . '/devotion/')
if !isdirectory(s:devotion_dir) | call mkdir(s:devotion_dir, "p") | endif

let g:devotion#log_file = expand(s:devotion_dir . 'devotion.log')
let g:devotion#debug_enabled = v:true  " TODO
let g:devotion#debug_file = expand(s:devotion_dir . 'debug.log')
" debugèÓïÒ
" event, localtime, file, elapsed_time

let g:devotion#view_timer_ = g:devotion#timer#Timer.New('view')
let g:devotion#edit_timer_ = g:devotion#timer#Timer.New('edit')

" utilities

function! g:devotion#GetEventBufferFileName()
  return expand("<afile>:p")
endfunction

function! g:devotion#GetEventBufferFileType()
  return getbufvar(str2nr(expand("<abuf>")), "&filetype")
endfunction

function! g:devotion#IsTargetFileType() abort
  let l:filetype = devotion#GetEventBufferFileType()
  if (l:filetype ==# "vim") || (l:filetype ==# "help")
    return v:true
  else
    return v:false
  endif
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
  call g:devotion#log#Log.LogEventInfo('BufEnter   ')
  call g:devotion#view_timer_.Initialize(devotion#GetEventBufferFileName())
  call g:devotion#view_timer_.Start()
  call g:devotion#edit_timer_.Initialize(devotion#GetEventBufferFileName())
endfunction

function! g:devotion#BufLeave() abort
  call g:devotion#log#Log.LogEventInfo('BufLeave   ')
  call g:devotion#view_timer_.Stop()
  call g:devotion#log#Log.LogElapsedTime(g:devotion#view_timer_)
  call g:devotion#log#Log.LogElapsedTime(g:devotion#edit_timer_)
  call g:devotion#view_timer_.Clear()
  call g:devotion#edit_timer_.Clear()
endfunction

function! g:devotion#BufUnload() abort
  call g:devotion#log#Log.LogEventInfo('BufUnload  ')
  call g:devotion#BufLeave()
endfunction

function! g:devotion#InsertEnter() abort
  call g:devotion#log#Log.LogEventInfo('InsertEnter')
  call g:devotion#view_timer_.Stop()
  call g:devotion#edit_timer_.Start()
endfunction

function! g:devotion#InsertLeave() abort
  call g:devotion#log#Log.LogEventInfo('InsertLeave')
  call g:devotion#view_timer_.Start()
  call g:devotion#edit_timer_.Stop()
endfunction

function! g:devotion#FocusLost() abort
  call g:devotion#log#Log.LogEventInfo('FocusLost  ')
  call g:devotion#view_timer_.SuspendIfNeeded()
  call g:devotion#edit_timer_.SuspendIfNeeded()
endfunction

function! g:devotion#FocusGained() abort
  call g:devotion#log#Log.LogEventInfo('FocusGained')
  call g:devotion#view_timer_.RestartIfNeeded()
  call g:devotion#edit_timer_.RestartIfNeeded()
endfunction
