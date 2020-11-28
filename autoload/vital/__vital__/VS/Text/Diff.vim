"
" is_lua_enabled
"
function! s:is_lua_enabled(is_lua_enabled) abort
  let s:is_lua_enabled = a:is_lua_enabled
endfunction

"
" compute
"
function! s:compute(old, new) abort
  let l:old = a:old
  let l:new = a:new

  let l:old_len = len(l:old)
  let l:new_len = len(l:new)
  let l:min_len = min([l:old_len, l:new_len])

  " empty -> empty
  if l:old_len == 0 && l:new_len == 0
    return {
    \   'range': {
    \     'start': {
    \       'line': 0,
    \       'character': 0,
    \     },
    \     'end': {
    \       'line': 0,
    \       'character': 0,
    \     }
    \   },
    \   'text': '',
    \   'rangeLength': 0
    \ }
  " not empty -> empty
  elseif l:old_len != 0 && l:new_len == 0
    return {
    \   'range': {
    \     'start': {
    \       'line': 0,
    \       'character': 0,
    \     },
    \     'end': {
    \       'line': l:old_len - 1,
    \       'character': strchars(l:old[-1]),
    \     }
    \   },
    \   'text': '',
    \   'rangeLength': strchars(join(l:old, "\n"))
    \ }
  " empty -> not empty
  elseif l:old_len == 0 && l:new_len != 0
    return {
    \   'range': {
    \     'start': {
    \       'line': 0,
    \       'character': 0,
    \     },
    \     'end': {
    \       'line': 0,
    \       'character': 0,
    \     }
    \   },
    \   'text': join(l:new, "\n"),
    \   'rangeLength': 0
    \ }
  endif

  if s:is_lua_enabled
    let [l:first_line, l:last_line, l:first_char, l:last_char, l:old_lines, l:new_lines, l:old_text, l:new_text, l:old_text_len, l:new_text_len] = luaeval('vital_vs_text_diff_compute(_A[1], _A[2])', [l:old, l:new])
  else
    let [l:first_line, l:last_line, l:first_char, l:last_char, l:old_lines, l:new_lines, l:old_text, l:new_text, l:old_text_len, l:new_text_len] = s:_compute(l:old, l:new, l:old_len, l:new_len, l:min_len)
  endif

  return {
  \   'range': {
  \     'start': {
  \       'line': l:first_line,
  \       'character': l:first_char,
  \     },
  \     'end': {
  \       'line': l:old_len + l:last_line,
  \       'character': strchars(l:old_lines[-1]) + l:last_char + 1,
  \     }
  \   },
  \   'text': strcharpart(l:new_text, l:first_char, l:new_text_len + l:last_char - l:first_char),
  \   'rangeLength': l:old_text_len + l:last_char - l:first_char
  \ }
endfunction

"
" _compute
"
function! s:_compute(old, new, old_len, new_len, min_len) abort
  for l:first_line in range(0, a:min_len - 1)
    if a:old[l:first_line] !=# a:new[l:first_line]
      break
    endif
  endfor

  for l:last_line in range(-1, (-a:min_len + l:first_line), -1)
    if a:old[l:last_line] !=# a:new[l:last_line]
      break
    endif
  endfor

  let l:old_lines = a:old[l:first_line : l:last_line]
  let l:new_lines = a:new[l:first_line : l:last_line]
  let l:old_text = join(l:old_lines, "\n") . "\n"
  let l:new_text = join(l:new_lines, "\n") . "\n"
  let l:old_text_len = strchars(l:old_text)
  let l:new_text_len = strchars(l:new_text)
  let l:min_text_len = min([l:old_text_len, l:new_text_len])

  let l:first_char = 0
  for l:first_char in range(0, l:min_text_len - 1)
    if strgetchar(l:old_text, l:first_char) != strgetchar(l:new_text, l:first_char)
      break
    endif
  endfor

  let l:last_char = 0
  for l:last_char in range(0, -l:min_text_len + l:first_char, -1)
    if strgetchar(l:old_text, l:old_text_len + l:last_char - 1) != strgetchar(l:new_text, l:new_text_len + l:last_char - 1)
      break
    endif
  endfor

  return [l:first_line, l:last_line, l:first_char, l:last_char, l:old_lines, l:new_lines, l:old_text, l:new_text, l:old_text_len, l:new_text_len]
endfunction

let s:is_lua_enabled = v:false
function! s:try_enable_lua() abort
lua <<EOF
function vital_vs_text_diff_compute(old, new)
  local old_len = #old
  local new_len = #new
  local min_len = math.min(old_len, new_len)

  local first_line = 0
  while first_line < min_len - 1 do
    if old[first_line + 1] ~= new[first_line + 1] then
      break
    end
    first_line = first_line + 1
  end

  local last_line = -1
  while last_line > -min_len + first_line do
    if old[(old_len + last_line) + 1] ~= new[(new_len + last_line) + 1] then
      break
    end
    last_line = last_line - 1
  end

  local old_lines = {}
  for i = first_line, (old_len + last_line) do
    table.insert(old_lines, old[i + 1])
  end

  local new_lines = {}
  for i = first_line, (new_len + last_line) do
    table.insert(new_lines, new[i + 1])
  end

  local old_text = table.concat(old_lines, "\n") .. "\n"
  local new_text = table.concat(new_lines, "\n") .. "\n"

  local old_text_len = vim.fn.strchars(old_text)
  local new_text_len = vim.fn.strchars(new_text)
  local min_text_len = math.min(old_text_len, new_text_len)

  local first_char = 0
  while first_char < min_text_len - 1 do
    if vim.fn.strgetchar(old_text, first_char) ~= vim.fn.strgetchar(new_text, first_char) then
      break
    end
    first_char = first_char + 1
  end

  local last_char = 0
  while last_char > -min_text_len + first_char do
    if vim.fn.strgetchar(old_text, old_text_len + last_char - 1) ~= vim.fn.strgetchar(new_text, new_text_len + last_char - 1) then
      break
    end
    last_char = last_char - 1
  end

  return { first_line, last_line, first_char, last_char, old_lines, new_lines, old_text, new_text, old_text_len, new_text_len }
end
EOF
let s:is_lua_enabled = v:true
endfunction

if has('nvim')
  try
    call s:try_enable_lua()
  catch /.*/
  endtry
endif

