if (has('nvim') && !has('nvim-0.5')) || (!has('nvim') && v:version < 800) || exists('g:initiated_vim_code_checker') || &cp
    finish
endif

let g:initiated_vim_code_checker = 1
let s:npmPluginSupportedVersion = '1.0.26-11'

"==============================================================================
" CONFIGURATION VARIABLES
"==============================================================================

" General settings
let g:code_checker_provider = get(g:, 'code_checker_provider', 'open-router')
let s:npmError = ''

"==============================================================================
" UTILITY FUNCTIONS 
"==============================================================================
function! s:get_visual_selection()
    " Why is this not a built-in Vim script function?!
    let [line_start, column_start] = getpos("'<")[1:2]
    let [line_end, column_end] = getpos("'>")[1:2]
    let lines = getline(line_start, line_end)
    if len(lines) == 0
        return ''
    endif
    let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
    let lines[0] = lines[0][column_start - 1:]
    return join(lines, "\n")
endfunction

function! s:getStartAndEndLineOfSelection()
  let [line_start, column_start] = getpos("'<")[1:2]
  let [line_end, column_end] = getpos("'>")[1:2]
  return [line_start, line_end]
endfunction


"==============================================================================
" FUNCTIONS 
"==============================================================================

:function! s:CodeCheck(method, question) range
  :cclose
  :redraw
  :call s:CallCodeCheck(a:method, a:question)
:endfunction

:function! s:CallCodeCheck(method, question) range
  if s:npmError != ''
    :echom s:npmError
    :echom "Please address the issue above and restart Vim."
    return
  endif
 
  :let l:selectedText = s:get_visual_selection()

  :let l:filename = expand('%')

  let l:providerText = ''
  let l:snippet = 0 
  let l:snippetText = ''
  let l:questionText = ''
  let l:linesText = ''

  if l:selectedText != '' && len(l:selectedText) > 1
    let l:startLine = s:getStartAndEndLineOfSelection()[0]
    let l:endLine = s:getStartAndEndLineOfSelection()[1]
    :let l:linesText = " --startLine " . (l:startLine) . " --endLine " . (l:endLine)
  endif

  :execute 'normal! y' 
  :exec 'normal! vy'

  if a:question != ''
    :let l:questionText = " --question '" . (a:question) . "'"  
  :endif

  :if g:code_checker_provider != ''
    :let l:providerText = "--provider " . (g:code_checker_provider)
  :endif

  let l:methodText = " --method " . a:method

  :if !empty(l:selectedText) && len(l:selectedText) > 1
    :let l:snippet = 1
    :echo "Checking selection (".g:code_checker_provider."). Please wait.."
  :else
    :echo "Checking file (".g:code_checker_provider."). Please wait.."
  :endif

  :let l:cmd = "emurph-code-checker " . l:methodText . " " . l:providerText . " --file " . (l:filename) . " " . l:linesText . " " . l:questionText 
  :unlet! l:endLine
  :unlet! l:filename
  :unlet! l:linesText
  :unlet! l:methodText
  :unlet! l:providerText
  :unlet! l:questionText
  :unlet! l:selectedText
  :unlet! l:snippet
  :unlet! l:snippetText
  :unlet! l:startLine

  :try
     :call s:AsyncSystemCall(['sh', '-c', l:cmd], function('HandleResult'))

  :catch
    :echo "Error: " . v:exception
  :endtry

  :execute 'normal! y' 
  :exec 'normal! vy'

  :unlet! l:cmd
:endfunction

function! s:AsyncSystemCall(cmd, callback)
  let l:options = {}
  let l:return_data = {'stdout': [], 'stderr': []}
  
  if has('nvim')
    " Neovim implementation
    function! l:options.on_stdout(job_id, data, event) closure
      if !empty(a:data)
        let l:return_data.stdout += a:data
      endif
    endfunction
    
    function! l:options.on_stderr(job_id, data, event) closure
      if !empty(a:data)
        let l:return_data.stderr += a:data
      endif
    endfunction
    
    function! l:options.on_exit(job_id, exit_code, event) closure
      " Filter out empty lines that Neovim might add
      call filter(l:return_data.stdout, {idx, val -> !empty(val)})
      call filter(l:return_data.stderr, {idx, val -> !empty(val)})
      call a:callback(l:return_data)
    endfunction
    
    let l:job = jobstart(a:cmd, l:options)
  else
    " Vim implementation
    function! l:options.out_cb(channel, message) closure
      let l:return_data.stdout += [a:message]
    endfunction
    
    function! l:options.err_cb(channel, message) closure
      let l:return_data.stderr += [a:message]
    endfunction
    
    function! l:options.close_cb(channel) closure
      call a:callback(l:return_data)
    endfunction
    
    let l:options.mode = 'nl'
    let l:job = job_start(a:cmd, l:options)
  endif
  
  return l:job
endfunction

function! HandleResult(result)
  " echom "STDOUT: " . join(a:result.stdout, "\n")
  " echom "STDERR: " . join(a:result.stderr, "\n")
  :let l:jsonFixes = json_decode(a:result.stdout)
  :try 
      :silent! call setqflist(l:jsonFixes, 'r')
  :catch
    :echo "Error parsing JSON response from server."
  :endtry
  :if len(l:jsonFixes) > 0
    :try
      :copen 
    :catch
      :echo "Error opening quickfix window."
    :endtry
  :endif
endfunction

"============================================================================== 
"--------- INITIALIZATION
"==============================================================================

function! HandleNpmVersionCB(result)
  let l:plugin = join(a:result.stdout, "\n")
  if empty(l:plugin)
    let s:npmError =  "emurph-code-checker is not installed. Please install it globally using npm. In your terminal, run: npm install -g emurph-code-checker"
    echom s:npmError
    return 0 
  endif
  " Check that plugin matches the supported major version
  let l:version = substitute(l:plugin, '.*emurph-code-checker@', '', '')
  " remove the trailing ^@
  let l:version = substitute(l:version, '\n', '', '')

  " get the major version from a value like 2.4.0-beta-2
  let l:majorVersion = substitute(l:version, '\v^([0-9]+)\..*', '\1', '')
  if floor(str2nr(l:majorVersion)) != floor(str2nr(s:npmPluginSupportedVersion))
    let s:npmError = "Version (".l:version.") of emurph-code-checker is not supported. Supported version: " . s:npmPluginSupportedVersion . ". You can fix this issue by running: npm i -g emurph-code-checker@". s:npmPluginSupportedVersion.". The recommended fix would be to update both your vim plugin (e.g :PluginUpdate whatever555/vim-code-checker) and the npm plugin (npm i -g emurph-code-checker@latest) to the latest versions."
    echom s:npmError
    return 0
  endif
  return 1
endfunction

function! s:checkNpmPlugin()
  let l:cmd = "npm list -g emurph-code-checker --depth=0 | grep emurph-code-checker"

  :try
    :call s:AsyncSystemCall(['sh', '-c', l:cmd], function('HandleNpmVersionCB'))
  :catch
    :echo "Error: " . v:exception
  :endtry

endfunction
:call s:checkNpmPlugin()


:command! -range CodeCheck <line1>,<line2> call s:CodeCheck('check', '')
:command! -range CodeCheckExplain <line1>,<line2>  call s:CodeCheck('explain', '')
:command! -range -nargs=1 CodeCheckAskQuestion <line1>,<line2>  call s:CodeCheck('question', <q-args>)
