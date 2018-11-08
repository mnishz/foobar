let s:STATE_NOT_STARTED = 'not_started'
let s:STATE_STARTED = 'started'
let s:STATE_SUSPENDED = 'suspended'

unlockvar g:devotion#timer#Timer

let g:devotion#timer#Timer = {
      \ 'mode': '',
      \ 'file_name': '',
      \ 'started_time': [],
      \ 'elapsed_time': 0.0,
      \ 'state': s:STATE_NOT_STARTED,
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

function! g:devotion#timer#Timer.Clear() abort
  if self.state != s:STATE_NOT_STARTED
    " unexpected
  endif
  let self.file_name = ''
  let self.elapsed_time = 0.0
  let self.state = s:STATE_NOT_STARTED
endfunction

function! g:devotion#timer#Timer.Start() abort
  if !self.IsSameFileName()
    " unexpected
    let self.file_name = devotion#GetEventBufferFileName()
  elseif self.state != s:STATE_NOT_STARTED
    " unexpected
  endif
  " continue regardless of error for Start()
  let self.started_time = reltime()
  let self.state = s:STATE_STARTED
endfunction

function! g:devotion#timer#Timer.Stop() abort
  if !self.IsSameFileName() || (self.state != s:STATE_STARTED)
    " unexpected
  else
    " add only in normal case in contrast to Start()
    let self.elapsed_time += reltimefloat(reltime(self.started_time))
    let self.state = s:STATE_NOT_STARTED
  endif
endfunction

function! g:devotion#timer#Timer.SuspendIfNeeded() abort
  if !self.IsSameFileName() || (self.state == s:STATE_SUSPENDED)
    " unexpected
  else
    if self.state == s:STATE_NOT_STARTED
      " do nothing
    elseif self.state == s:STATE_STARTED
      " add only in normal case in contrast to Restart()
      let self.elapsed_time += reltimefloat(reltime(self.started_time))
      let self.state = s:STATE_SUSPENDED
    endif
  endif
endfunction

function! g:devotion#timer#Timer.RestartIfNeeded() abort
  if !self.IsSameFileName() || (self.state == s:STATE_STARTED)
    " unexpected
  endif
  " continue regardless of error for Restart()
  if self.state == s:STATE_NOT_STARTED
    " do nothing
  elseif self.state == s:STATE_SUSPENDED
    let self.started_time = reltime()
    let self.state = s:STATE_STARTED
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
    if self.state != s:STATE_NOT_STARTED
      " unexpected
    endif
    return self.elapsed_time
  endif
endfunction

function! g:devotion#timer#Timer.IsSameFileName() abort
  if !empty(self.file_name) && (self.file_name ==# devotion#GetEventBufferFileName())
    return v:true
  else
    return v:false
  endif
endfunction

lockvar g:devotion#timer#Timer
