unlockvar g:logger#Logger

let g:logger#Logger = {}

function! g:logger#Logger.WriteElapsedTimeLog(timer) abort
  let l:data = {
        \ 't': eval(strftime("%Y%m%d%H%M%S")),
        \}
  " localtime -> こっちで取れる
  " elapsed time -> もらう必要がある(timer)
  " mode: view, edit -> もらう必要がある(timer)
  " filetype: vim, help -> こっちで取れる
  " file name -> もらう必要がある(timer)
endfunction

function! g:logger#Logger.WriteDebugLog() abort
  if g:devotion#debug_enabled
  endif
endfunction

lockvar g:logger#Logger
