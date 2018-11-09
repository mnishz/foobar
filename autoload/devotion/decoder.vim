scriptencoding utf-8

" 結果の書き出し
" for idx in range(0, 100000)
"   let s:log = {'t': <SID>GetDayNum(idx), 'e': 1.0, 'ft': 'vim', 'm': 'V', 'f': 'W:\.vimrc'}
"   call writefile([string(s:log)], 'W:\.cache\hoge.log', 'a')
" endfor

" 結果の読み出し
" let s:log = readfile('W:\.cache\hoge.log')
let s:log = readfile('W:\.cache\devotion.txt')
" string
" echo s:log[0]
" echo s:log[1]
" dictionary
" echo eval(s:log[0])
" echo eval(s:log[0]).t

" binary search, そこそこ早い
function! s:TimeBinarySearch(target_time_num) abort
  let l:left_idx = -1
  let l:right_idx = len(s:log)

  while l:right_idx - l:left_idx > 1
    let l:mid_idx = l:left_idx + (l:right_idx - l:left_idx) / 2
    if eval(s:log[l:mid_idx]).t >= a:target_time_num
      let l:right_idx = l:mid_idx
    else
      let l:left_idx = l:mid_idx
    endif
  endwhile

  return l:right_idx
endfunction

" echo <SID>TimeBinarySearch(2010101000000)

function! s:AddUpAndShowElapsedTime(start_time_num, stop_time_num) abort
  " TODO: error check
  let l:first_idx = <SID>TimeBinarySearch(a:start_time_num)
  " TODO: 見つかったとか、見つからなかったとか、最後のエントリを含む含まないとか要確認
  let l:last_idx = <SID>TimeBinarySearch(a:stop_time_num) - 1

  let l:elapsed_time_list = []
  let l:NOT_FOUND = -1 | lockvar! l:NOT_FOUND

  for log_str_line in s:log[l:first_idx:l:last_idx]
    " if log_str_line[3:7] ==# 'debug' | continue | endif
    let l:log_dict = eval(log_str_line)

    let l:same_file_idx = l:NOT_FOUND
    for idx in range(0, len(l:elapsed_time_list)-1)
      if l:elapsed_time_list[idx].file ==# l:log_dict.f
        let l:same_file_idx = idx
        break
      endif
    endfor
    if l:same_file_idx == l:NOT_FOUND
      " TODO: クラスに初期化関数を作りたい、拡張性のため
      let l:elapsed_time_list += [{'file': l:log_dict.f, 'filetype': l:log_dict.ft, 'view': 0.0, 'edit': 0.0}]
      let l:same_file_idx = -1  " assume it to be the last one
    endif
    let l:elapsed_time_list[l:same_file_idx][l:log_dict.m] += l:log_dict.e
  endfor

  return l:elapsed_time_list
endfunction

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

" 文字列として記憶して、日付だけ文字列のindexとして出すかな。。
" 同じ桁数だったら2286年までいける

" 1個書き込むのはいいけど、全体を(辞書として)読み出すのはすごく時間がかかる
" あと辞書だと順番が保証されない
" let s:log = {
"       \ 'time': localtime(),
"       \ 'elps': 5.0,
"       \ 'mode': 'VV',
"       \ 'file': 'W:\.vimrc',
"       \}
" call writefile([string(s:log)], 'W:\.cache\hoge.log', 'a')

" listの中身は文字列か数字でないといけないのでNG
" let s:log = []
" call add(s:log, [localtime(), 5.0, 'VV', 'W:\.vimrc'])
" call add(s:log, [localtime(), 7.0, 'VV', 'W:\.vimrc'])
" " echo s:log

" 結果の読み込み
" let s:stored = '['
" for s:line in readfile('W:\.cache\hoge.log')
"   let s:stored .= s:line . ', '
" endfor
" let s:stored .= ']'
" let s:log = eval(s:stored)
" echo s:log[0]
" echo s:log[1]
" echo eval(s:log[0]).time
" echo eval(s:log[1]).time

" この場合、Mylen() は単に辞書から呼べるよという定義であって
" 特定の辞書との結びつきはない
" function! s:Mylen() dict
"   return len(self.data)
" endfunction
" 
" " len() == 4
" unlet! s:mydict
" let s:mydict = {'data': [0, 1, 2, 3], 'len': function("Mylen")}
" echo s:mydict.len()
" 
" " foo() == 5
" unlet! s:anotherDict
" let s:anotherDict = {'name': "Nishihata", 'data': [2, 4, 6, 8, 10], 'foo': function("Mylen")}
" echo s:anotherDict.foo()
" 
" " 呼び出すことはできるが、data メンバがないので Mylen() 内部でエラーとなる
" " let hogeDict = {'huga': function("Mylen")}
" " echo hogeDict.huga()
" 
" 
" 
" unlet! s:Timer
" let s:Timer = {
"       \ 'elapsed_time': 0.0,
"       \ 'is_stopped': 1,
"       \ }
" 
" " 先に s:Timer を宣言しておかないと、そんなものないと怒られる
" " なので、この関数と s:Timer には明確な繋がりがある
" function! s:Timer.GetElapsedTime()
"   return self.elapsed_time
" endfunction
" 
" function! s:Timer.SetElapsedTime(new_time)
"   let self.elapsed_time = a:new_time
" endfunction
" 
" call s:Timer.SetElapsedTime(2.0)
" echo s:Timer.GetElapsedTime()
" 
" echo s:Timer
" 
" " 他の辞書と結び付けようとしてもそんな関数知らないと言われる
" " let barDict = {'getter': function("s:Timer.GetElapsedTime"), 'elapsed_time': 5.0}
" " echo barDict.getter()
