scriptencoding utf-8

" constants

let s:STATE_CLEARED = 'cleared'
let s:STATE_NOT_STARTED = 'not_started'
let s:STATE_STARTED = 'started'
let s:STATE_SUSPENDED = 'suspended'

" class

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
  call g:devotion#log#Log.LogTimerEvent(self, 'Initialize')
  if !empty(self.file_name)
    call g:devotion#log#Log.LogUnexpectedState()
  endif
  call self.Clear()
  let self.state = s:STATE_NOT_STARTED
  let self.file_name = a:file_name
endfunction

function! g:devotion#timer#Timer.Clear() abort
  call g:devotion#log#Log.LogTimerEvent(self, 'Clear')
  if self.state != s:STATE_NOT_STARTED
    call g:devotion#log#Log.LogUnexpectedState()
  endif
  let self.file_name = ''
  let self.elapsed_time = 0.0
  let self.state = s:STATE_CLEARED
endfunction

function! g:devotion#timer#Timer.Start() abort
  call g:devotion#log#Log.LogTimerEvent(self, 'Start')
  if !self.IsSameFileName()
    call g:devotion#log#Log.LogUnexpectedState()
    let self.file_name = devotion#GetEventBufferFileName()
  elseif self.state != s:STATE_NOT_STARTED
    call g:devotion#log#Log.LogUnexpectedState()
  endif
  " continue regardless of error for Start()
  let self.started_time = reltime()
  let self.state = s:STATE_STARTED
endfunction

function! g:devotion#timer#Timer.Stop() abort
  call g:devotion#log#Log.LogTimerEvent(self, 'Stop')
  if !self.IsSameFileName() || (self.state != s:STATE_STARTED)
    call g:devotion#log#Log.LogUnexpectedState()
  else
    " add only in normal case in contrast to Start()
    call self.CalcAndAddElapsedTime()
    let self.state = s:STATE_NOT_STARTED
  endif
endfunction

function! g:devotion#timer#Timer.SuspendIfNeeded() abort
  call g:devotion#log#Log.LogTimerEvent(self, 'Suspend')
  if !self.IsSameFileName() || (self.state == s:STATE_SUSPENDED)
    call g:devotion#log#Log.LogUnexpectedState()
  else
    if self.state == s:STATE_NOT_STARTED
      " do nothing
    elseif self.state == s:STATE_STARTED
      " add only in normal case in contrast to Restart()
      call self.CalcAndAddElapsedTime()
      let self.state = s:STATE_SUSPENDED
    endif
  endif
endfunction

function! g:devotion#timer#Timer.RestartIfNeeded() abort
  call g:devotion#log#Log.LogTimerEvent(self, 'Restart')
  if !self.IsSameFileName() || (self.state == s:STATE_STARTED)
    call g:devotion#log#Log.LogUnexpectedState()
  endif
  " continue regardless of error for Restart()
  if self.state == s:STATE_NOT_STARTED
    " do nothing
  elseif self.state == s:STATE_SUSPENDED
    let self.started_time = reltime()
    let self.state = s:STATE_STARTED
  endif
endfunction

function! g:devotion#timer#Timer.GetElapsedTime() abort
  call g:devotion#log#Log.LogTimerEvent(self, 'GetElapsed')
  if !self.IsSameFileName()
    call g:devotion#log#Log.LogUnexpectedState()
  else
    if self.state != s:STATE_NOT_STARTED
      call g:devotion#log#Log.LogUnexpectedState()
    endif
    return self.elapsed_time
  endif
endfunction

function! g:devotion#timer#Timer.GetElapsedTimeWoCheck() abort
  return self.elapsed_time
endfunction

function! g:devotion#timer#Timer.GetMode() abort
  return self.mode
endfunction

function! g:devotion#timer#Timer.GetFileName() abort
  return self.file_name
endfunction

function! g:devotion#timer#Timer.GetState() abort
  return self.state
endfunction

function! g:devotion#timer#Timer.IsCleared() abort
  return (self.state ==# s:STATE_CLEARED) ? v:true : v:false
endfunction

function! g:devotion#timer#Timer.CalcAndAddElapsedTime() abort
  let l:curr_elapsed_time = reltimefloat(reltime(self.started_time))
  if l:curr_elapsed_time >= 0.0
    let self.elapsed_time += l:curr_elapsed_time
  else
    call g:devotion#log#Log.LogNegativeElapsedTime(string(l:curr_elapsed_time))
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
