unlockvar g:logger#Logger

let g:logger#Logger = {}

function! g:logger#Logger.WriteElapsedTimeLog(timer) abort
  let l:data = {
        \ 't': eval(strftime("%Y%m%d%H%M%S")),
        \}
  " localtime -> �������Ŏ���
  " elapsed time -> ���炤�K�v������(timer)
  " mode: view, edit -> ���炤�K�v������(timer)
  " filetype: vim, help -> �������Ŏ���
  " file name -> ���炤�K�v������(timer)
endfunction

function! g:logger#Logger.WriteDebugLog() abort
  if g:devotion#debug_enabled
  endif
endfunction

lockvar g:logger#Logger
