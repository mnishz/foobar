" variables
let g:devotion#viewTimer = g:timer#Timer.New()
let g:devotion#editTimer = g:timer#Timer.New()

" utilities

function devotion#IsTargetBuffer() abort
  let l:filetype = getbufvar(str2nr(expand("<abuf>")), "&filetype")
  if l:filetype ==# "vim" || l:filetype ==# "help"
    return v:true
  else
    return v:false
  endif
endfunction

function! devotion#GetBufferFileName()
  return expand("<afile>:p")
endfunction

" autocmd functions

function devotion#BufEnter() abort
  call g:devotion#viewTimer.Initialize(devotion#GetBufferFileName())
  call g:devotion#viewTimer.Start()
endfunction

function devotion#BufLeave() abort
  call g:devotion#viewTimer.Stop()
  echo g:devotion#viewTimer.GetElapsedTime()
  call g:devotion#viewTimer.Clear()
endfunction

function devotion#BufUnload() abort
  call g:devotion#viewTimer.Stop()
  echo g:devotion#viewTimer.GetElapsedTime()
  call g:devotion#viewTimer.Clear()
endfunction

function devotion#InsertEnter() abort
endfunction

function devotion#InsertLeave() abort
endfunction

function devotion#FocusLost() abort
endfunction

function devotion#FocusGained() abort
endfunction
