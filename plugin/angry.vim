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
  " In visual mode, start searching from the end of the selection.  This way
  " the selection will extend naturally when repeating the text object.
  if a:0 | exe "normal! `>" | endif

  " Find beginning of object and store if it is a comma or opening bracket.
  if searchpair('(', ',', ')', 'bW') <= 0 | return | endif
  exe "normal! yl"
  let left = @@

  " Find end of object and store if it is a comma or closing bracket.
  if searchpair('(', ',', ')', 'sW') <= 0 | return | endif
  exe "normal! yl"
  let right = @@

  if right == ','
    " Include space after comma at the end of argument.
    let extra = "wh"
  else
    " Don't include closing bracket, but include space before argument.  Also
    " include comma before argument if there is one (the alternative is that
    " there is an opening bracket).
    let extra = "ho`'" . (left != "," ? "lo" : "o")
  endif

  if a:0
    let [b0,l0,c0,o0] = getpos("'<")
    let [b1,l1,c1,o1] = getpos("''")
    if l0 < l1 || c0 < c1
      " The old visual area extends further at the beginning than our new
      " visual area does.  Extend the new area to include the old.  This
      " ensures that we can keep extending the visual selection by repeatedly
      " typing command sequence for the text object.
      let extra .= "o`<o"
    endif
  endif

  exe "normal! v`'wo" . extra

endfunction
