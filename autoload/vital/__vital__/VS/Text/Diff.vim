"
" compute
"
function! s:compute(old, new) abort
  let l:old = a:old + ['']
  let l:new = a:new + ['']

  let l:old_len = len(l:old)
  let l:new_len = len(l:new)
  let l:min_len = min([l:old_len, l:new_len])

  " first different line.
  let l:first_line = 0
  while l:first_line < l:min_len - 1
    if l:old[l:first_line] !=# l:new[l:first_line]
      break
    endif
    let l:first_line += 1
  endwhile

  " last different line.
  let l:last_line = -1
  while l:last_line > -l:min_len + l:first_line
    if l:old[l:last_line] !=# l:new[l:last_line]
      break
    endif
    let l:last_line -= 1
  endwhile

  let l:old_lines = l:old[l:first_line : l:last_line]
  let l:new_lines = l:new[l:first_line : l:last_line]
  let l:old_text = join(l:old_lines, "\n")
  let l:new_text = join(l:new_lines, "\n")
  let l:old_text_len = strchars(l:old_text)
  let l:new_text_len = strchars(l:new_text)
  let l:min_text_len = min([l:old_text_len, l:new_text_len])

  let l:first_char = 0
  while l:first_char < l:min_text_len - 1
    if strgetchar(l:old_text, l:first_char) != strgetchar(l:new_text, l:first_char)
      break
    endif
    let l:first_char += 1
  endwhile

  let l:last_char = 0 " exclusive
  while l:last_char > -l:min_text_len + l:first_char
    if strgetchar(l:old_text, (l:old_text_len + l:last_char) - 1) != strgetchar(l:new_text, (l:new_text_len + l:last_char) - 1)
      break
    endif
    let l:last_char -= 1
  endwhile

  let l:range_length = strchars(strcharpart(l:old_text, l:first_char, l:old_text_len + l:last_char - l:first_char))
  let l:text = strcharpart(l:new_text, l:first_char, l:new_text_len + l:last_char - l:first_char)

  let l:diff = {}
  let l:diff.range = {}
  let l:diff.range.start = {}
  let l:diff.range.start.line = l:first_line
  let l:diff.range.start.character = l:first_char
  let l:diff.range.end = {}
  let l:diff.range.end.line = l:old_len + l:last_line
  let l:diff.range.end.character = strchars(l:old_lines[-1]) + l:last_char
  let l:diff.text = l:text
  let l:diff.rangeLength = l:range_length
  return l:diff
endfunction

