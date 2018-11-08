" utilities
function! s:GetDateTimeStr() abort
  return strftime('%Y%m%d%H%M%S')
endfunction

" class

unlockvar g:devotion#log#Log

let g:devotion#log#Log = {}

function! g:devotion#log#Log.LogElapsedTime(timer) abort
  if !empty(a:timer.GetElapsedTime())
    let l:data = {
          \ 't':  eval(s:GetDateTimeStr()),
          \ 'e':  a:timer.GetElapsedTime(),
          \ 'm':  a:timer.GetMode(),
          \ 'ft': devotion#GetEventBufferFileType(),
          \ 'f':  a:timer.GetFileName(),
          \}
    call writefile([string(l:data)], g:devotion#log_file, 'a')
  endif
endfunction

function! g:devotion#log#Log.AddUpAndShowElapsedTime(start, stop) abort
"   let l:log = readfile(g:devotion#log_file)
  let l:log = readfile('W:\.cache\hoge.log')
endfunction

" function! s:TimeBinarySearch(log, time) abort
function! g:devotion#log#Log.TimeBinarySearch(log, time) abort
  " under: -1, over: -2
  " 2018/01/01 �̕����o�͂���� (start < stop �̏����v�m�F)
  " 20180101000000 �� 20180102000000 �Ŏ󂯎���āA���� -1 ����
  " 20180101235959 �ŒT���B�ǂ��炩���͈͓��ɂ��邩�Aunder && over �̂Ƃ��ɏo
  " �͂�����̂�����B���̂Ƃ��� -1 ���������ꍇ�� 0 �ɁA-2 ���������ꍇ�� N-1
  " �ɏ���������B
  " for (int i = min; (i <= max): ++i) �܂ő������ށB
  if eval(a:log[0]).t > a:time | return -1 | endif
  if eval(a:log[-1]).t < a:time | return -2 | endif
  let l:left_idx = -1
  let l:right_idx = len(a:log)
  while l:right_idx - l:left_idx > 1
    let l:mid_idx = l:left_idx + (l:right_idx - l:left_idx) / 2
    if eval(a:log[l:mid_idx]).t >= a:time
      let l:right_idx = l:mid_idx
    else
      let l:left_idx = l:mid_idx
    endif
  endwhile
  return l:right_idx
endfunction

function! g:devotion#log#Log.LogAutocmdEvent(event) abort
  if g:devotion#debug_enabled
    let l:data = a:event
    let l:data .= ' ' . s:GetDateTimeStr()
    let l:data .= ' ' . g:devotion#GetEventBufferFileName()
    call writefile([l:data], g:devotion#debug_file, 'a')
  endif
endfunction

function! g:devotion#log#Log.LogTimerEvent(timer, function) abort
  if g:devotion#debug_enabled
    let l:data = '  ' . a:timer.GetMode() . ' ' . a:function . ' '
    let l:data .= a:timer.GetFileName() . ' ' . a:timer.GetState() . ' '
    let l:data .= string(a:timer.GetElapsedTimeWoCheck())
    call writefile([l:data], g:devotion#debug_file, 'a')
  endif
endfunction

function! g:devotion#log#Log.LogUnexpectedState() abort
  if g:devotion#debug_enabled
    call writefile(['    !!!! unexpected state !!!!'], g:devotion#debug_file, 'a')
    echoerr 'devotion: unexpected state'
  endif
endfunction

function! g:devotion#log#Log.LogNegativeElapsedTime(time) abort
  if g:devotion#debug_enabled
    call writefile(['    !!!! negative elapsed time ' . a:time . ' !!!!'], g:devotion#debug_file, 'a')
    echoerr 'devotion: negative elapsed time'
  endif
endfunction

lockvar g:devotion#log#Log
