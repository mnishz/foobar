" TODO: Vim global plugin for correcting typing mistakes
" Last Change:  2018/10/22
" Maintainer:   Masato Nishihata
" License:      This file is placed in the public domain.

if exists("g:loaded_devotion")
  finish
endif
let g:loaded_devotion = 1

let s:save_cpo = &cpo
set cpo&vim

" let s:DEBUG_MODE = v:true | lockvar! s:DEBUG_MODE

" TODO: use XDG_CACHE_HOME?
" TODO: �N�P�ʂ��炢�Ńt�@�C���𕪂���H
let s:log_file_name = expand("~/.cache/devotion.log")
let s:result_file_name = expand("~/.cache/devotion.txt")

let s:target_file_name = ""

" assumption
"
" BufEnter
" |
" | FocusLost
" | |
" | V
" | FocusGained
" |
" | InsertEnter
" | |
" | | FocusLost
" | | |
" | | V
" | | FocusGained
" | V
" | InsertLeave
" V
" BufLeave/BufUnload

" TODO: �e event �̓��e���֐�������
" TODO: ���ʏ����𔲂��o��
" TODO: �t�@�C���^�C�v�v���O�C���ł���K�v�́H
" TODO: debug �p�f�[�^�̍폜
" TODO: Enter �ł� status �`�F�b�N�͂Ȃ��ق���������������Ȃ��A��蓦�����Ƃ��̂��߂�
" TODO: ���ʕ\���֐� or �R�}���h�̍쐬
" TODO: vim�̑��N�����Ԃ�����Ɣ�r���ł��ėǂ�����
" TODO: ���t�̏o�͂� strftime() ���� localtime() �̂ق��������Ƃ��e�ʂƂ���
" ����� better ���Ǝv��
" TODO: �o�ߎ��Ԃ� 0 �Ȃ�ȗ�
" TODO: ����t�@�C�����ǂ����̃`�F�b�N�������
" TODO: �t�@�C������������݂̂̂ɍi��
" TODO: help �t�@�C�������Aview�ƁA�|��p��edit
" TODO: autoload ��
" �����ɉ�������̂��������TODO�Ƃ���GitHub�ɏ����Ă����Ă悢��������Ȃ�

" vim �t�@�C�����J���āA���̃t�@�C���Ɉړ�������� :qa �����
" BufLeave BufUnload �̏��ŃC�x���g����������

" filetype������̂͂��߂��B�B<abuf>����o�b�t�@�̏��𔲂��o���K�v������
" ����Ő����H getbufvar(str2nr(expand("<abuf>")), "&filetype")

augroup devotion
  autocmd!
  autocmd BufEnter *    if g:devotion#IsTargetFileType() | call g:devotion#BufEnter()    | endif
  autocmd BufLeave *    if g:devotion#IsTargetFileType() | call g:devotion#BufLeave()    | endif
  autocmd BufUnload *   if g:devotion#IsTargetFileType() | call g:devotion#BufUnload()   | endif
  autocmd InsertEnter * if g:devotion#IsTargetFileType() | call g:devotion#InsertEnter() | endif
  autocmd InsertLeave * if g:devotion#IsTargetFileType() | call g:devotion#InsertLeave() | endif
  autocmd FocusLost *   if g:devotion#IsTargetFileType() | call g:devotion#FocusLost()   | endif
  autocmd FocusGained * if g:devotion#IsTargetFileType() | call g:devotion#FocusGained() | endif
augroup END

" autocmd functions

function! s:DevotionBufEnter()
  let l:buffer_file_name = s:GetBufferFileName()
  let l:time = localtime()
  call s:LogEventTime("BufEnter", l:time, l:buffer_file_name)

  " continue even if the status is not expected one because this is the beginning of everything
  if s:monitoring_status != s:NOT_MONITORING | call s:LogStatusError() | endif

  let s:monitoring_status = s:MONITORING
  let s:buf_enter_time = l:time
  let s:target_file_name = l:buffer_file_name
endfunction

function! s:DevotionBufLeave()
  let l:buffer_file_name = s:GetBufferFileName()
  let l:time = localtime()
  call s:LogEventTime("BufLeave", l:time, l:buffer_file_name)

  " return in case of error because elapsed time cannot be calculated
  if s:monitoring_status != s:MONITORING | call s:LogStatusError() | return | endif
  if !s:IsTargetFile(l:buffer_file_name) | return | endif

  let s:monitoring_status = s:NOT_MONITORING
  let l:elapsed_time = s:CalcBufElapsedTime(l:time)
  call s:LogBufElapsedTime(l:time, l:elapsed_time, l:buffer_file_name)
  call s:ClearBufElapsedParam()
endfunction

function! s:DevotionBufUnload()
  let l:buffer_file_name = s:GetBufferFileName()
  let l:time = localtime()
  call s:LogEventTime("BufUnload", l:time, l:buffer_file_name)

  " BufLeave -> BufUnload can be happen (e.g. :tabnew -> :qa), just log and return
  if s:monitoring_status == s:NOT_MONITORING | call s:LogBufLeaveUnloadEvent() | return | endif
  " return in case of error because elapsed time cannot be calculated
  if s:monitoring_status != s:MONITORING | call s:LogStatusError() | return | endif
  if !s:IsTargetFile(l:buffer_file_name) | return | endif

  let s:monitoring_status = s:NOT_MONITORING
  let l:elapsed_time = s:CalcBufElapsedTime(l:time)
  call s:LogBufElapsedTime(l:time, l:elapsed_time, l:buffer_file_name)
  call s:ClearBufElapsedParam()
endfunction

function! s:DevotionInsertEnter()
  let l:buffer_file_name = s:GetBufferFileName()
  let l:time = localtime()
  call s:LogEventTime("InsertEnter", l:time, l:buffer_file_name)

  " return in case of error because elapsed time cannot be calculated
  if s:monitoring_status != s:MONITORING | call s:LogStatusError() | return | endif
  if !s:IsTargetFile(l:buffer_file_name) | return | endif

  let s:monitoring_status = s:MONITORING_INSERT
  let s:insert_enter_time = l:time
endfunction

function! s:DevotionInsertLeave()
  let l:buffer_file_name = s:GetBufferFileName()
  let l:time = localtime()
  call s:LogEventTime("InsertLeave", l:time, l:buffer_file_name)

  " return in case of error because elapsed time cannot be calculated
  if s:monitoring_status != s:MONITORING_INSERT | call s:LogStatusError() | return | endif
  if !s:IsTargetFile(l:buffer_file_name) | return | endif

  let s:monitoring_status = s:MONITORING
  let l:elapsed_time = s:CalcInsertElapsedTime(l:time)
  call s:LogInsertElapsedTime(l:time, l:elapsed_time, l:buffer_file_name)
  call s:ClearInsertElapsedParam()
endfunction

function! s:DevotionFocusLost()
  let l:buffer_file_name = s:GetBufferFileName()
  let l:time = localtime()
  call s:LogEventTime("FocusLost", l:time, l:buffer_file_name)

  " return in case of error because elapsed time cannot be calculated
  if !s:IsTargetFile(l:buffer_file_name) | return | endif
  " continue even if the status is not expected one because this is the beginning of FocusLost
  if !s:has_focus | call s:LogStatusError() | endif

  let s:has_focus = v:false
  let s:focus_lost_time = l:time
endfunction

function! s:DevotionFocusGained()
  let l:buffer_file_name = s:GetBufferFileName()
  let l:time = localtime()
  call s:LogEventTime("FocusGained", l:time, l:buffer_file_name)

  " return in case of error because elapsed time cannot be calculated
  if s:has_focus | call s:LogStatusError() | return | endif
  if !s:IsTargetFile(l:buffer_file_name) | return | endif

  if s:monitoring_status == s:MONITORING
    let s:buf_focus_lost_time += l:time() - s:focus_lost_time
  elseif s:monitoring_status == s:MONITORING_INSERT
  else
  endif

  if getbufvar(str2nr(expand("<abuf>")), "&filetype") ==# "vim" && expand("<afile>") ==# s:target_file_name
    if s:focus_status != 0 | echoerr "devotion" | call writefile(["FocusGained Status Error 1", s:focus_status], s:log_file_name, "a") | endif
    let s:focus_status = 1
    call writefile(["FocusGained @ " . localtime() . " for " . expand("<afile>:p")], s:log_file_name, "a")
    if s:monitoring_status == 1
      let s:total_focus_lost_time_for_buf_enter += localtime() - s:focus_gained_timestamp
      if s:total_focus_lost_time_for_buf_enter < 0 | echoerr "devotion" | call writefile(["FocusGained Time Error"], s:log_file_name, "a") | endif
    elseif s:monitoring_status == 2
      let s:total_focus_lost_time_for_buf_enter += localtime() - s:focus_gained_timestamp
      if s:total_focus_lost_time_for_buf_enter < 0 | echoerr "devotion" | call writefile(["FocusGained Time Error"], s:log_file_name, "a") | endif
      let s:total_focus_lost_time_for_insert_enter += localtime() - s:focus_gained_timestamp
      if s:total_focus_lost_time_for_insert_enter < 0 | echoerr "devotion" | call writefile(["FocusGained Time Error"], s:log_file_name, "a") | endif
    else
      echoerr "devotion" | call writefile(["FocusGained Status Error 2", s:monitoring_status], s:log_file_name, "a")
    endif
  endif
endfunction

" ���ʂ͎����̃��X�g�Ŏ��̂�������������
" [
"   {
"     filename: "filename",
"     viewing_time: string or int,
"     editing_time: string or int,
"   },
"   {
"     filename: "filename",
"     viewing_time: string or int,
"     editing_time: string or int,
"   },
" ]
" binary search �� first line �� last line �����߂āA
" �t�@�C�������������� list ��ǉ�
" ���̌�e���l�𑝂₷ -> string �ł͂Ȃ��� int �̂ق����������낤
" �t�@�C���̊J�����́Actrlp �� mru ���Q�l�ɂȂ邩��
" :DevotionRange
" :DevotionLastDay (�O���ł͂Ȃ��A�ŏI�g�p������������)
" :DevotionLastWeek

let &cpo = s:save_cpo
unlet s:save_cpo
