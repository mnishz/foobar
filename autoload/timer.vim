let s:Timer = {
      \ 'file_name': '',
      \ 'started_time': [],
      \ 'elapsed_time': 0.0,
      \ 'is_stopped': v:true,
      \ }

function! s:Timer.New() abort
  let l:timer = copy(self)
  return l:timer
endfunction

function! s:Timer.Initialize(file_name) abort
  let self.file_name = a:file_name
  let self.elapsed_time = 0.0
  let self.is_stopped = v:true
endfunction

function! s:Timer.Start() abort
  if self.is_stopped
    let self.started_time = reltime()
    let self.is_stopped = v:false
  else
  endif
endfunction

function! s:Timer.Stop() abort
  if !self.is_stopped
    let self.elapsed_time += reltimefloat(reltime(self.started_time))
    let self.is_stopped = v:true
  else
  endif
endfunction

function! s:Timer.GetElapsedTime() abort
  return self.elapsed_time
endfunction

" let fooTimer = s:Timer.New()
" call fooTimer.Initialize('hogehoge.vim')
" call fooTimer.Start()
call fooTimer.Stop()
echo fooTimer.GetElapsedTime()
