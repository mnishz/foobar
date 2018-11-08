unlockvar g:devotion#log#Log

let g:devotion#log#Log = {}

function! g:devotion#log#Log.LogElapsedTime(timer) abort
  let l:data = {
        \ 't':  eval(strftime("%Y%m%d%H%M%S")),
        \ 'e':  a:timer.GetElapsedTime(),
        \ 'm':  a:timer.GetMode(),
        \ 'ft': devotion#GetEventBufferFileType(),
        \ 'f':  a:timer.GetFileName(),
        \}
  call writefile([string(l:data)], g:devotion#log_file, 'a')
endfunction

function! g:devotion#log#Log.LogDebugInfo() abort
  if g:devotion#debug_enabled
  endif
endfunction

lockvar g:devotion#log#Log
