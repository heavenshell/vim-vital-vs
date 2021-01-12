let s:namespace = {}
let s:prop_id = 0
let s:prop_priority = 0
let s:prop_types = {}
let s:prop_cache = {} " { ['ns'] => [...ids] }

"
" is_available
"
function! s:is_available() abort
  if has('nvim')
    return exists('*nvim_buf_set_text')
  else
    return exists('*prop_type_add') && exists('*prop_add') && exists('*prop_find') && exists('*prop_list')
  endif
endfunction

"
" @param {number} bufnr
" @param {string} ns
" @param {array} marks
" @param {[number, number]} marks[number].start_pos
" @param {[number, number]} marks[number].end_pos
" @param {string?}          marks[number].highlight
"
function! s:set(bufnr, ns, marks) abort
  call s:_set(bufnr(a:bufnr), a:ns, a:marks)
endfunction

"
" get
"
" @param {number} bufnr
" @param {string} ns
" @param {[number, number]?} pos
" @returns {array}
"
function! s:get(bufnr, ns, ...) abort
  let l:pos = get(a:000, 0, [])
  return s:_get(bufnr(a:bufnr), a:ns, l:pos)
endfunction

"
" clear
"
" @param {number} bufnr
" @param {string} ns
"
function! s:clear(bufnr, ns) abort
  return s:_clear(bufnr(a:bufnr), a:ns)
endfunction

if has('nvim')
  "
  " set
  "
  function! s:_set(bufnr, ns, marks) abort
    if !has_key(s:namespace, a:ns)
      let s:namespace[a:ns] = nvim_create_namespace(a:ns)
    endif
    for l:mark in a:marks
      let l:opts = {
      \   'end_line': l:mark.end_pos[0] - 1,
      \   'end_col': l:mark.end_pos[1] - 1,
      \ }
      if has_key(l:mark, 'highlight')
        let l:opts.hl_group = l:mark.highlight
      endif
      call nvim_buf_set_extmark(
      \   a:bufnr,
      \   s:namespace[a:ns],
      \   l:mark.start_pos[0] - 1,
      \   l:mark.start_pos[1] - 1,
      \   l:opts
      \ )
    endfor
  endfunction

  "
  " get
  "
  function! s:_get(bufnr, ns, pos) abort
    if !has_key(s:namespace, a:ns)
      return []
    endif
    let l:extmarks = nvim_buf_get_extmarks(a:bufnr, s:namespace[a:ns], 0, -1, { 'details': v:true })
    if !empty(a:pos)
      let l:marks = []
      for l:extmark in l:extmarks " TODO: efficiency.
        let l:mark = s:_from_extmark(l:extmark)
        let l:contains = v:true
        let l:contains = l:contains && l:mark.start_pos[0] < a:pos[0] || (l:mark.start_pos[0] == a:pos[0] && l:mark.start_pos[1] <= a:pos[1])
        let l:contains = l:contains && l:mark.end_pos[0] > a:pos[0] || (l:mark.end_pos[0] == a:pos[0] && l:mark.end_pos[1] >= a:pos[1])
        if !l:contains
          continue
        endif
        let l:marks += [l:mark]
      endfor
      return l:marks
    else
      return map(l:extmarks, 's:_from_extmark(v:val)')
    endif
  endfunction

  "
  " clear
  "
  function! s:_clear(bufnr, ns) abort
    if !has_key(s:namespace, a:ns)
      return
    endif
    call nvim_buf_clear_namespace(a:bufnr, s:namespace[a:ns], 0, -1)
  endfunction

  "
  " from_extmark
  "
  function! s:_from_extmark(extmark) abort
    let l:mark = {}
    let l:mark.start_pos = [a:extmark[1] + 1, a:extmark[2] + 1]
    let l:mark.end_pos = [a:extmark[3].end_row + 1, a:extmark[3].end_col + 1]
    if has_key(a:extmark[3], 'hl_group')
      let l:mark.highlight = a:extmark[3].hl_group
    endif

    " swap ranges if needed.
    if l:mark.start_pos[0] > l:mark.end_pos[0] || (l:mark.start_pos[0] == l:mark.end_pos[0] && l:mark.start_pos[1] > l:mark.end_pos[1])
      let l:start_pos = l:mark.start_pos
      let l:mark.start_pos = l:mark.end_pos
      let l:mark.end_pos = l:start_pos
    endif

    return l:mark
  endfunction
else
  "
  " set
  "
  function! s:_set(bufnr, ns, marks) abort
    " preare namespace.
    let l:cache = s:_ensure_cache(a:bufnr, a:ns)
    for l:mark in a:marks
      let s:prop_id += 1
      call add(l:cache.ids, s:prop_id)
      call prop_add(l:mark.start_pos[0], l:mark.start_pos[1], {
      \   'id': s:prop_id,
      \   'bufnr': a:bufnr,
      \   'end_lnum': l:mark.end_pos[0],
      \   'end_col': l:mark.end_pos[1],
      \   'type': s:_ensure_type(l:mark)
      \ })
    endfor
  endfunction

  "
  " get
  "
  function! s:_get(bufnr, ns, pos) abort
    let l:marks = []
    for l:prop_id in s:_ensure_cache(a:bufnr, a:ns).ids
      let l:prop = prop_find({ 'id': l:prop_id, 'lnum': 1, 'col': 1, })
      if empty(l:prop)
        continue
      endif

      let l:start_lnum = l:prop.lnum
      let l:start_col = l:prop.col
      if l:prop.end
        let l:end_lnum = l:start_lnum
        let l:end_col = l:start_col + l:prop.length
      else
        let l:i = 1
        while 1
          let l:ends = filter(prop_list(l:start_lnum + l:i, { 'id': l:prop_id }), 'v:val.id == l:prop_id') " it seems vim's bug
          if empty(l:ends)
            let l:i += 1
            continue
          endif
          let l:end = l:ends[0]
          if !l:end.end
            let l:i += 1
            continue
          endif
          let l:end_lnum = l:start_lnum + l:i
          let l:end_col = l:end.col + l:end.length
          break
        endwhile
      endif

      " position check if specified.
      if !empty(a:pos)
        let l:contains = v:true
        let l:contains = l:contains && l:start_lnum < a:pos[0] || (l:start_lnum == a:pos[0] && l:start_col <= a:pos[1])
        let l:contains = l:contains && l:end_lnum > a:pos[0] || (l:end_lnum == a:pos[0] && l:end_col >= a:pos[1])
        if !l:contains
          continue
        endif
      endif

      let l:mark = {}
      let l:mark.start_pos = [l:start_lnum, l:start_col]
      let l:mark.end_pos = [l:end_lnum, l:end_col]
      if has_key(s:prop_types[l:prop.type], 'highlight')
        let l:mark.highlight = s:prop_types[l:prop.type].highlight
      endif
      call add(l:marks, l:mark)
    endfor
    return l:marks
  endfunction

  "
  " clear
  "
  function! s:_clear(bufnr, ns) abort
    let l:cache = s:_ensure_cache(a:bufnr, a:ns)
    for l:prop_id in l:cache.ids
      call prop_remove({ 'bufnr': a:bufnr, 'id': l:prop_id })
    endfor
    let l:cache.ids = []
  endfunction

  "
  " ensure_type
  "
  function! s:_ensure_type(mark) abort
    let l:type = printf('VS.Vim.Buffer.TextMark: %s', get(a:mark, 'highlight', ''))
    if !has_key(s:prop_types, l:type)
      let s:prop_priority += 1
      let s:prop_types[l:type] = {
      \   'start_incl': v:true,
      \   'end_incl': v:true,
      \ }
      if has_key(a:mark, 'highlight')
        let s:prop_types[l:type].highlight = a:mark.highlight
      endif
      call prop_type_add(l:type, s:prop_types[l:type])
    endif
    return l:type
  endfunction

  "
  " ensure_cache
  "
  function! s:_ensure_cache(bufnr, ns) abort
    let l:key = printf('VS.Vim.Buffer.TextMark: %s: %s', a:bufnr, a:ns)
    if !has_key(s:prop_cache, l:key)
      let s:prop_cache[l:key] = { 'ids': [] }
    endif
    return s:prop_cache[l:key]
  endfunction
endif
