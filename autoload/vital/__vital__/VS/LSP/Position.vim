"
" cursor
"
function! s:cursor() abort
  return s:vim_to_lsp('%', getpos('.')[1 : 3])
endfunction

"
" vim_to_lsp
"
function! s:vim_to_lsp(expr, pos) abort
  let l:line = s:_get_buffer_line(a:expr, a:pos[0])
  if l:line is v:null
    return {
    \   'line': a:pos[0] - 1,
    \   'character': a:pos[1] + a:pos[2] - 1
    \ }
  endif

  return {
  \   'line': a:pos[0] - 1,
  \   'character': strchars(strpart(l:line, 0, a:pos[1] + get(a:pos, 2, 0) - 1))
  \ }
endfunction

"
" lsp_to_vim
"
function! s:lsp_to_vim(expr, position) abort
  let l:line = s:_get_buffer_line(a:expr, a:position.line + 1)
  if l:line is v:null
    return [a:position.line + 1, a:position.character + 1]
  endif
  return [a:position.line + 1, strlen(strcharpart(l:line, 0, a:position.character)) + 1]
endfunction

"
" _get_buffer_line
"
function! s:_get_buffer_line(expr, lnum) abort
  if bufloaded(bufnr(a:expr))
    return get(getbufline(a:expr, a:lnum), 0, v:null)
  elseif filereadable(a:expr)
    if exists('*bufload')
      call bufload(bufnr(a:expr, v:true))
      return get(getbufline(a:expr, a:lnum), 0, v:null)
    endif
    return get(readfile(a:expr, '', a:lnum), 0, v:null)
  endif
  return v:null
endfunction

