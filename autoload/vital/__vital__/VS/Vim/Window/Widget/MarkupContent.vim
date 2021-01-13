function! s:_vital_loaded(V) abort
  let s:Markdown = a:V.import('VS.Vim.Syntax.Markdown')
  let s:Window = a:V.import('VS.Vim.Window')
  let s:FloatingWindow = a:V.import('VS.Vim.Window.FloatingWindow')
endfunction

function! s:_vital_depends() abort
  return ['VS.Vim.Syntax.Markdown', 'VS.Vim.Window', 'VS.Vim.Window.FloatingWindow']
endfunction

"
" is_available
"
function! s:is_available() abort
  return s:FloatingWindow.is_available()
endfunction

"
" new
"
function! s:new(args) abort
  return s:MarkupContent.new(a:args)
endfunction

let s:id = 0

let s:MarkupContent = {}

"
" new
"
" @param args.minwidth
" @param args.maxwidth
" @param args.minheight
" @param args.maxheight
"
function! s:MarkupContent.new(args) abort
  let s:id += 1

  let l:bufnr = bufnr(printf('VS.Vim.Window.Widget.MarkupContent:%s', s:id), v:true)
  call bufload(l:bufnr)
  call setbufvar(l:bufnr, '&buflisted', 0)
  call setbufvar(l:bufnr, '&modeline', 0)
  call setbufvar(l:bufnr, '&buftype', 'nofile')
  call setbufvar(l:bufnr, '&bufhidden', 'hide')
  call setbufvar(l:bufnr, '&textwidth', 0)
  return extend(deepcopy(s:MarkupContent), {
  \   'bufnr': l:bufnr,
  \   'window': s:FloatingWindow.new(),
  \   'minwidth': get(a:args, 'minwidth', -1),
  \   'maxwidth': get(a:args, 'maxwidth', -1),
  \   'minheight': get(a:args, 'minheight', -1),
  \   'maxheight': get(a:args, 'maxheight', -1),
  \ })
endfunction

"
" open
"
" @param {number} args.row
" @param {number} args.col
" @param {string[]} args.contents
"
function! s:MarkupContent.open(args) abort
  call deletebufline(self.bufnr, '^', '$')
  call setbufline(self.bufnr, 1, a:args.contents)

  let l:size = s:FloatingWindow.get_size({
  \   'minwidth': self.minwidth,
  \   'maxwidth': self.maxwidth,
  \   'minheight': self.minheight,
  \   'maxheight': self.maxheight,
  \ }, a:args.contents)

  call self.window.open({
  \   'bufnr': self.bufnr,
  \   'row': a:args.row,
  \   'col': a:args.col,
  \   'width': l:size.width,
  \   'height': l:size.height,
  \ })
  call setwinvar(self.window.win, '&wrap', 1)
  call setwinvar(self.window.win, '&conceallevel', 2)
  call s:Window.do(self.window.win, { -> s:Markdown.apply() })
endfunction

"
" close
"
function! s:MarkupContent.close() abort
  call self.window.close()
endfunction

"
" close
"
function! s:MarkupContent.close() abort
  call self.window.close()
endfunction
