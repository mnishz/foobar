let s:suite = themis#suite('test for autoload/log.vim')
let s:assert = themis#helper('assert')

function! s:suite.log_empty_test() abort
  let l:log_files = glob(g:devotion#log_file . '*', v:true, v:true)
  for log_file in l:log_files
    call delete(log_file)
  endfor
  let l:result = g:devotion#log#AddUpElapsedTime(
        \ 19700101000000,
        \ 19700102000000)
  call s:assert.empty(l:result)
endfunction

function! s:suite.log_single_edit_test() abort
  let l:file_name = fnamemodify('test/log.vim', ':p')
  let l:timer = g:devotion#timer#Timer.New('edit')
  call l:timer.Initialize(l:file_name)
  let l:timer.elapsed_time = 1.0
  call g:devotion#log#LogElapsedTime(l:timer, 19700101000000)
  let l:result = g:devotion#log#AddUpElapsedTime(
        \ 19700101000000,
        \ 19700102000000)
  " filetype is not set because actual autocmd does
  let l:expected = [{
        \ 'file': l:file_name,
        \ 'filetype': '',
        \ 'vim': 0.0,
        \ 'edit': 1.0,
        \ 'view': 0.0,
        \ 'total': 1.0}]
  call s:assert.equals(l:result, l:expected)
endfunction
