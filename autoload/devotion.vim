" variables
let s:devotion_dir = empty($XDG_DATA_HOME) ? '~/.local/share' : $XDG_DATA_HOME
let s:devotion_dir = expand(s:devotion_dir . '/devotion/')
if !isdirectory(s:devotion_dir) | call mkdir(s:devotion_dir, "p") | endif

let g:devotion#log_file = expand(s:devotion_dir . 'devotion.log')
let g:devotion#debug_enabled = v:true  " TODO
let g:devotion#debug_file = expand(s:devotion_dir . 'debug.log')
" debug情報
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

function! g:devotion#BufEnter() abort
  call g:devotion#view_timer_.Initialize(devotion#GetEventBufferFileName())
  call g:devotion#view_timer_.Start()
  " debug用logを書き出してくれる人を呼ぶ
endfunction

function! g:devotion#BufLeave() abort
  call g:devotion#view_timer_.Stop()
  " debug用logを書き出してくれる人を呼ぶ
  call g:devotion#log#Log.LogElapsedTime(g:devotion#view_timer_)
  call g:devotion#view_timer_.Clear()
endfunction

function! g:devotion#BufUnload() abort
endfunction

function! g:devotion#InsertEnter() abort
endfunction

function! g:devotion#InsertLeave() abort
endfunction

function! g:devotion#FocusLost() abort
endfunction

function! g:devotion#FocusGained() abort
endfunction
