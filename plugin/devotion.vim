" TODO: Vim global plugin for correcting typing mistakes
" Last Change:  2018/10/22
" Maintainer:   Masato Nishihata
" License:      This file is placed in the public domain.

if exists('g:loaded_devotion')
  finish
endif
let g:loaded_devotion = 1

let s:save_cpo = &cpo
set cpo&vim

scriptencoding utf-8

" TODO: �N�P�ʂ��炢�Ńt�@�C���𕪂���H
" TODO: �ǂݍ��݂̂ق��͌�łǂ��ɂł��Ȃ邯�ǁA�������݂̂ق��͉�������ł���
" ���Ȃ��Ƃ����Ȃ��C������B
" TODO: ���ʕ\���֐� or �R�}���h�̍쐬
" TODO: vim�̑��N�����Ԃ�����Ɣ�r���ł��ėǂ�����
" TODO: release�O��debug�𗎂Ƃ�
" �����ɉ�������̂��������TODO�Ƃ���GitHub�ɏ����Ă����Ă悢��������Ȃ�

" ���{��͉��̂ق��ɂ���Ə����āA�p�� -> ���{��̏��ɏ���
" pure Vim script
" �s���R�Ȍ��t������\�����������狳���Ă�

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

command! -nargs=+ DevotionRange call g:devotion#Range(<f-args>)
command! DevotionToday     call g:devotion#Today()
command! DevotionLastDay   call g:devotion#LastDay()
command! DevotionThisWeek  call g:devotion#ThisWeek()
command! DevotionLastWeek  call g:devotion#LastWeek()
command! DevotionThisMonth call g:devotion#ThisMonth()
command! DevotionLastMonth call g:devotion#LastMonth()
command! DevotionThisYear  call g:devotion#ThisYear()
command! DevotionLastYear  call g:devotion#LastYear()

let &cpo = s:save_cpo
unlet s:save_cpo
