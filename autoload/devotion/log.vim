" utilities
function! s:GetDateTimeStr() abort
  return strftime("%Y%m%d%H%M%S")
endfunction

" class

unlockvar g:devotion#log#Log

let g:devotion#log#Log = {}

function! g:devotion#log#Log.LogElapsedTime(timer) abort
  if !empty(a:timer.GetElapsedTime())
    let l:data = {
          \ 't':  eval(s:GetDateTimeStr()),
          \ 'e':  a:timer.GetElapsedTime(),
          \ 'm':  a:timer.GetMode(),
          \ 'ft': devotion#GetEventBufferFileType(),
          \ 'f':  a:timer.GetFileName(),
          \}
    call writefile([string(l:data)], g:devotion#log_file, 'a')
  endif
endfunction

function! g:devotion#log#Log.LogAutocmdEvent(event) abort
  if g:devotion#debug_enabled
    let l:data = a:event
    let l:data .= ' ' . s:GetDateTimeStr()
    let l:data .= ' ' . g:devotion#GetEventBufferFileName()
    call writefile([l:data], g:devotion#debug_file, 'a')
  endif
endfunction

function! g:devotion#log#Log.LogTimerEvent(timer, function) abort
  if g:devotion#debug_enabled
    let l:data = '  ' . a:timer.GetMode() . ' ' . a:function . ' '
    let l:data .= a:timer.GetFileName() . ' ' . a:timer.GetState() . ' '
    let l:data .= string(a:timer.GetElapsedTimeWoCheck())
    call writefile([l:data], g:devotion#debug_file, 'a')
  endif
endfunction

function! g:devotion#log#Log.LogUnexpectedState() abort
  if g:devotion#debug_enabled
    call writefile(['    !!!! unexpected state !!!!'], g:devotion#debug_file, 'a')
    echoerr 'devotion: unexpected state'
  endif
endfunction

function! g:devotion#log#Log.LogNegativeElapsedTime(time) abort
  if g:devotion#debug_enabled
    call writefile(['    !!!! negative elapsed time ' . a:time . ' !!!!'], g:devotion#debug_file, 'a')
    echoerr 'devotion: negative elapsed time'
  endif
endfunction

lockvar g:devotion#log#Log
