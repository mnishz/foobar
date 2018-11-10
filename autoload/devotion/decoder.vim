scriptencoding utf-8

" 2018/10/29 の定時間内の結果を見る
" echo <SID>AddUpAndShowElapsedTime(20181029000000, 20190101000000)
" call <SID>AddUpAndShowElapsedTime(20181029000000, 20181030000000)

function! s:GetDayNum(day_offset)
  " TODO: list か何かにしてまとめて返さないと、日付をまたぐときにおかしくなる
  let l:time = localtime() + (a:day_offset * 60 * 60 * 24)
  let l:day = eval(strftime("%Y%m%d%H%M%S", l:time))
  return (l:day - (l:day % 1000000))
endfunction

command! DevotionToday call <SID>DevotionToday()

function! s:DevotionToday() abort
  let l:result = <SID>AddUpAndShowElapsedTime(<SID>GetDayNum(0), <SID>GetDayNum(1))
  echo 'You devoted your following time to Vim.'
  for entry in l:result
    echo '  Viewed: ' . string(entry.v) . ' sec, Edited: ' . string(entry.e) . ' sec, File: ' . entry.file . ', filetype: ' . entry.filetype
  endfor
endfunction
