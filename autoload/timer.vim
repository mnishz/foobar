" how to use
" let fooTimer = g:timer#Timer.New()
" call fooTimer.Initialize('hogehoge.vim')
" call fooTimer.Start()
" sleep 3
" call fooTimer.Stop()
" echo fooTimer.GetElapsedTime()

" BufEnter viewTimer.Initialize()/viewTimer.Start()
" |
" | FocusLost viewTimer.Stop()
" x |
" x V
" | FocusGained viewTimer.Start()
" |
" | InsertEnter viewTimer.Stop() / editTimer.Initialize()/editTimer.Start()
" x |
" x | FocusLost editTimer.Stop()
" x x |
" x x V
" x | FocusGained editTimer.Start()
" x V
" | InsertLeave editTimer.Stop()/editTimer.GetElapsedTime()/editTimer.Clear() / viewTimer.Start()
" V
" BufLeave/BufUnload viewTimer.Stop()/viewTimer.GetElapsedTime()/viewTimer.Clear()

unlockvar g:timer#Timer

let g:timer#Timer = {
      \ 'file_name': '',
      \ 'started_time': [],
      \ 'elapsed_time': 0.0,
      \ 'is_stopped': v:true,
      \ }

function! g:timer#Timer.New() abort
  let l:timer = copy(self)
  return l:timer
endfunction

function! g:timer#Timer.Initialize(file_name) abort
  if !empty(self.file_name)
    " unexpected
  endif
  call self.Clear()
  let self.file_name = a:file_name
endfunction

function! g:timer#Timer.Start() abort
  if empty(self.file_name) || !self.is_stopped
    " unexpected
  else
    let self.started_time = reltime()
    let self.is_stopped = v:false
  endif
endfunction

function! g:timer#Timer.Stop() abort
  if empty(self.file_name) || self.is_stopped
    " unexpected
  else
    let self.elapsed_time += reltimefloat(reltime(self.started_time))
    let self.is_stopped = v:true
  endif
endfunction

function! g:timer#Timer.GetElapsedTime() abort
  if empty(self.file_name) || !self.is_stopped
    " unexpected
  else
    return self.elapsed_time
  endif
endfunction

function! g:timer#Timer.Clear() abort
  let self.file_name = ''
  let self.elapsed_time = 0.0
  let self.is_stopped = v:true
endfunction

lockvar g:timer#Timer
