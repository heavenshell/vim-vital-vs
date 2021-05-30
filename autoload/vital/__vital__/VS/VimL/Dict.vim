"
" get
"
function! s:get(dict, keys, ...) abort
  let l:default = get(a:000, 0, v:null)
  let l:V = a:dict
  for l:key in a:keys
    let l:type = type(l:V)
    if !(l:type == v:t_dict && has_key(l:V, l:key))
      return l:default
    endif
    let l:V = l:V[l:key]
  endfor
  return l:V
endfunction

"
" set
"
function! s:set(dict, keys, value) abort
  let l:V = a:dict
  for l:i in range(0, len(a:keys) - 2)
    if type(l:V) != v:t_dict
      throw printf('VS.VimL.Dict: `%s` is not dict.', a:keys[0 : l:i])
    endif
    let l:key = a:keys[l:i]
    let l:V[l:key] = get(l:V, l:key, {})
    let l:V = l:V[l:key]
  endfor
  if type(l:V) != v:t_dict
    throw printf('VS.VimL.Dict: `%s` is not dict.', a:keys[:  -2])
  endif
  let l:V[a:keys[-1]] = a:value
endfunction


"
" remove
"
function! s:remove(dict, keys) abort
  let l:V = a:dict
  for l:i in range(0, len(a:keys) - 2)
    if type(l:V) != v:t_dict
      throw printf('VS.VimL.Dict: `%s` is not dict.', a:keys[0 : l:i])
    endif
    let l:key = a:keys[l:i]
    let l:V[l:key] = get(l:V, l:key, {})
    let l:V = l:V[l:key]
  endfor
  if type(l:V) != v:t_dict
    throw printf('VS.VimL.Dict: `%s` is not dict.', a:keys[: -2])
  endif
  unlet l:V[a:keys[-1]]
endfunction

