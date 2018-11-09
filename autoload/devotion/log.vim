scriptencoding utf-8

" constants

let s:TIME_FOUND = 0  | lockvar s:TIME_FOUND
let s:TIME_UNDER = -1 | lockvar s:TIME_UNDER
let s:TIME_OVER  = -2 | lockvar s:TIME_OVER
let s:MODE_FIRST = 0  | lockvar s:MODE_FIRST
let s:MODE_LAST  = 1  | lockvar s:MODE_LAST

" utilities

function! s:GetDateTimeStr() abort
  return strftime('%Y%m%d%H%M%S')
endfunction

" class

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

function! g:devotion#log#Log.AddUpElapsedTime(start_time, stop_time) abort
  " this function adds up from start_time to (stop_time - 1)
  if a:start_time >= a:stop_time | echoerr 'invalid args' | return [] | endif
  let l:logs = readfile(g:devotion#log_file)
  let l:first_idx = s:TimeSearch(l:logs, a:start_time, s:MODE_FIRST)
  let l:last_idx = s:TimeSearch(l:logs, a:stop_time - 1, s:MODE_LAST)

  let l:found = v:false
  if (l:first_idx > s:TIME_FOUND) || (l:last_idx > s:TIME_FOUND)
    let l:found = v:true
  elseif (l:first_idx == s:TIME_UNDER) && (l:last_idx == s:TIME_OVER)
    let l:found = v:true
  endif

  let l:first_idx = (l:first_idx == s:TIME_UNDER) ? 0 : l:first_idx
  let l:last_idx  = (l:last_idx  == s:TIME_OVER)  ? (len(l:logs) - 1) : l:last_idx

  let l:result_list = []
  if l:found
    let l:NOT_FOUND = -1 | lockvar l:NOT_FOUND
    for log_str_line in l:logs[l:first_idx:l:last_idx]
      let l:log_dict = eval(log_str_line)
      let l:result_idx = l:NOT_FOUND
      for idx in range(len(l:result_list))
        if l:result_list[idx].file ==# l:log_dict.f
          let l:result_idx = idx
          break
        endif
      endfor
      if l:result_idx == l:NOT_FOUND
        let l:result_list += [{'file': l:log_dict.f, 'filetype': l:log_dict.ft, 'view': 0.0, 'edit': 0.0}]
        let l:result_idx = -1  " assume it to be the last one
      endif
      let l:result_list[l:result_idx][l:log_dict.m] += l:log_dict.e
    endfor
  endif

  return l:result_list
endfunction

function! s:TimeSearch(logs, time, mode) abort
  if eval(a:logs[0]).t > a:time | return s:TIME_UNDER | endif
  if eval(a:logs[-1]).t < a:time | return s:TIME_OVER | endif

  " binary search for the first target timestamp
  let l:top_idx = -1
  let l:btm_idx = len(a:logs)
  while l:btm_idx - l:top_idx > 1
    let l:mid_idx = l:top_idx + (l:btm_idx - l:top_idx) / 2
    if eval(a:logs[l:mid_idx]).t >= a:time
      let l:btm_idx = l:mid_idx
    else
      let l:top_idx = l:mid_idx
    endif
  endwhile

  if a:mode == s:MODE_LAST
    while eval(a:logs[l:btm_idx]).t > a:time
      let l:btm_idx -= 1
    endwhile
  endif

  return l:btm_idx
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
