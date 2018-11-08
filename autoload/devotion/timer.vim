" how to use
" let fooTimer = g:devotion#timer#Timer.New()
" call fooTimer.Initialize('hogehoge.vim')
" call fooTimer.Start()
" sleep 3
" call fooTimer.Stop()
" echo fooTimer.GetElapsedTime()

" BufEnter view_timer_.Initialize()/Start()
" |
" | FocusLost view_timer_.Stop()
" x |
" x V
" | FocusGained view_timer_.Start()
" |
" | InsertEnter view_timer_.Stop()
" x |           edit_timer_.Initialize()/Start()
" x |
" x | FocusLost edit_timer_.Stop()
" x x |
" x x V
" x | FocusGained edit_timer_.Start()
" x V
" | InsertLeave edit_timer_.Stop()/GetElapsedTime()/Clear()
" |             view_timer_.Start()
" V
" BufLeave/BufUnload view_timer_.Stop()/GetElapsedTime()/Clear()

unlockvar g:devotion#timer#Timer

let g:devotion#timer#Timer = {
      \ 'mode': '',
      \ 'file_name': '',
      \ 'started_time': [],
      \ 'elapsed_time': 0.0,
      \ 'is_started': v:false,
      \ }

function! g:devotion#timer#Timer.New(mode) abort
  let l:timer = copy(self)
  let l:timer.mode = a:mode
  return l:timer
endfunction

function! g:devotion#timer#Timer.Initialize(file_name) abort
  if !empty(self.file_name)
    " unexpected
  endif
  call self.Clear()
  let self.file_name = a:file_name
endfunction

function! g:devotion#timer#Timer.Start() abort
  if !self.IsSameFileName()
    " unexpected
    let self.file_name = devotion#GetEventBufferFileName()
  elseif self.is_started
    " unexpected
  endif
  " continue regardless of error for Start()
  let self.started_time = reltime()
  let self.is_started = v:true
endfunction

function! g:devotion#timer#Timer.Stop() abort
  if !self.IsSameFileName() || !self.is_started
    " unexpected
  else
    " add only in normal case in contrast to Start()
    let self.elapsed_time += reltimefloat(reltime(self.started_time))
    let self.is_started = v:false
  endif
endfunction

function! g:devotion#timer#Timer.GetMode() abort
  return self.mode
endfunction

function! g:devotion#timer#Timer.GetFileName() abort
  return self.file_name
endfunction

function! g:devotion#timer#Timer.GetElapsedTime() abort
  if !self.IsSameFileName()
    " unexpected
  else
    if self.is_started
      " unexpected
    endif
    return self.elapsed_time
  endif
endfunction

function! g:devotion#timer#Timer.Clear() abort
  if self.is_started
    " unexpected
  endif
  let self.file_name = ''
  let self.elapsed_time = 0.0
  let self.is_started = v:false
endfunction

function! g:devotion#timer#Timer.IsSameFileName() abort
  if !empty(self.file_name) && (self.file_name ==# devotion#GetEventBufferFileName())
    return v:true
  else
    return v:false
  endif
endfunction

lockvar g:devotion#timer#Timer
