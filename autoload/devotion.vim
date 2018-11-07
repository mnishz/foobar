" variables
let s:DataHome = empty($XDG_DATA_HOME) ? '~/.local/share' : $XDG_DATA_HOME

let g:devotion#log_file = expand(s:DataHome . '/devotion.log')
let g:devotion#debug_enabled = v:true  " TODO
let g:devotion#debug_file = expand(s:DataHome . '/debug.log')
" debug情報
" event, localtime, file, elapsed_time

let g:devotion#view_timer_ = g:timer#Timer.New('v')
let g:devotion#edit_timer_ = g:timer#Timer.New('e')

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
  call g:devotion#view_timer_.Initialize(devotion#GetBufferFileName())
  call g:devotion#view_timer_.Start()
  " debug用logを書き出してくれる人を呼ぶ
endfunction

function devotion#BufLeave() abort
  call g:devotion#view_timer_.Stop()
  echo g:devotion#view_timer_.GetElapsedTime()
  call g:devotion#view_timer_.Clear()
  " debug用logを書き出してくれる人を呼ぶ
  " 記録用logを書き出してくれる人を呼ぶ
endfunction

function devotion#BufUnload() abort
  call g:devotion#view_timer_.Stop()
  echo g:devotion#view_timer_.GetElapsedTime()
  call g:devotion#view_timer_.Clear()
endfunction

function devotion#InsertEnter() abort
endfunction

function devotion#InsertLeave() abort
endfunction

function devotion#FocusLost() abort
endfunction

function devotion#FocusGained() abort
endfunction
