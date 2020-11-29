"
" _vital_loaded
"
function! s:_vital_loaded(V) abort
  let s:Emitter = a:V.import('VS.Event.Emitter')
endfunction

"
" _vital_depends
"
function! s:_vital_depends() abort
  return ['VS.Event.Emitter']
endfunction

"
" new
"
function! s:new(args) abort
  return s:Job.new(a:args)
endfunction

let s:chunk_size = 2048

let s:Job = {}

"
" new
"
function! s:Job.new(args) abort
  let l:job = extend(deepcopy(s:Job), {
  \   'command': a:args.command,
  \   'events': s:Emitter.new(),
  \   'write_buffer': '',
  \   'write_timer': -1,
  \   'job': v:null,
  \ })
  let l:job.write = function(l:job.write, [], l:job)
  return l:job
endfunction

"
" start
"
function! s:Job.start(...) abort
  if self.is_running()
    return
  endif

  let l:args = extend(get(a:000, 0, {}), { 'cwd': getcwd() }, 'keep')
  if !isdirectory(l:args.cwd) || l:args.cwd !~# '/'
    unlet l:args.cwd
  endif
  let self.job = s:_create(
  \   self.command,
  \   l:args,
  \   function(self.on_stdout, [], self),
  \   function(self.on_stderr, [], self),
  \   function(self.on_exit, [], self)
  \ )
endfunction

"
" stop
"
function! s:Job.stop() abort
  if !self.is_running()
    return
  endif
  call self.job.stop()
  let self.job = v:null
endfunction

"
" is_running
"
function! s:Job.is_running() abort
  return !empty(self.job)
endfunction

"
" send
"
function! s:Job.send(data) abort
  if !self.is_running()
    return
  endif
  let self.write_buffer .= a:data
  if self.write_timer != -1
    return
  endif
  call self.write()
endfunction

"
" write
"
function! s:Job.write(...) abort
  let self.write_timer = -1
  if self.write_buffer ==# ''
    return
  endif
  call self.job.send(strpart(self.write_buffer, 0, s:chunk_size))
  let self.write_buffer = strpart(self.write_buffer, s:chunk_size)
  if self.write_buffer !=# ''
    let self.write_timer = timer_start(0, self.write)
  endif
endfunction

"
" on_stdout
"
function! s:Job.on_stdout(data) abort
  call self.events.emit('stdout', a:data)
endfunction

"
" on_stderr
"
function! s:Job.on_stderr(data) abort
  call self.events.emit('stderr', a:data)
endfunction

"
" on_exit
"
function! s:Job.on_exit(code) abort
  call self.events.emit('exit', a:code)
endfunction

"
" create job instance
"
if has('nvim')
  function! s:_create(command, args, out, err, exit) abort
    let a:args.on_stdout = { id, data, event -> a:out(join(data, "\n")) }
    let a:args.on_stderr = { id, data, event -> a:err(join(data, "\n")) }
    let a:args.on_exit = { id, data, code -> a:exit(code) }
    let l:job = jobstart(a:command, a:args)
    return {
    \   'stop': { -> jobstop(l:job) },
    \   'send': { data -> jobsend(l:job, data) }
    \ }
  endfunction
else
  function! s:_create(command, args, out, err, exit) abort
    let a:args.noblock = v:true
    let a:args.in_io = 'pipe'
    let a:args.in_mode = 'raw'
    let a:args.out_io = 'pipe'
    let a:args.out_mode = 'raw'
    let a:args.err_io = 'pipe'
    let a:args.err_mode = 'raw'
    let a:args.out_cb = { job, data -> a:out(data) }
    let a:args.err_cb = { job, data -> a:err(data) }
    let a:args.exit_cb = { job, code -> a:exit(code) }
    let l:job = job_start(a:command, a:args)
    return {
    \   'stop': { ->  ch_close(l:job) },
    \   'send': { data -> ch_sendraw(l:job, data) }
    \ }
  endfunction
endif

