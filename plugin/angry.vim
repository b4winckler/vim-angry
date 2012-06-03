" Function argument text objects ('arg' means 'angry' in Swedish)
" Author:  Bjorn Winckler <bjorn.winckler@gmail.com>
" Version: 0.1

if exists("loaded_angry") || &cp || v:version < 700
  finish
endif
" let loaded_angry = 1

vnoremap <silent> <script> <Plug>OuterArg :<C-U>call <SID>ArgC(visualmode())<CR>
onoremap <silent> <script> <plug>OuterArg :call <SID>ArgC()<CR>

vmap <silent> aa <Plug>OuterArg
omap <silent> aa <Plug>OuterArg


function! s:ArgC(...)
  if searchpair('(', ',', ')', 'bW') <= 0 | return | endif
  exe "normal! yl"
  let left = @@

  if searchpair('(', ',', ')', 'sW') <= 0 | return | endif
  exe "normal! yl"
  let right = @@

  if right == ','
    " Include space after comma at the end of argument.
    let extra = "wh"
  else
    " Don't include closing parenthesis, but include space before argument.
    " Also include comma before argument if there is one (the alternative is
    " that there is an opening parenthesis).
    let extra = "ho`'" . (left != "," ? "lo" : "o")
  endif

  exe "normal! v`'wo" . extra

  " if a:0 > 0
  "   exe "normal! o`<o"
  " endif
endfunction
