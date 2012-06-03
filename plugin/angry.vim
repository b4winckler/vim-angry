" Function argument text objects ('arg' means 'angry' in Swedish)
" Author:  Bjorn Winckler <bjorn.winckler@gmail.com>
" Version: 0.1

if exists("loaded_angry") || &cp || v:version < 700
  finish
endif
" let loaded_angry = 1

if !exists("g:angry_max_count")
  " Upper bound on v:count for text objects.  This avoids needless processing
  " time when the count is much larger than the number of arguments.
  let g:angry_max_count = 50
endif

vnoremap <silent> <script> <Plug>AngryOuter :<C-U>call
      \ <SID>ArgCstyle(min([g:angry_max_count, v:count1]), visualmode())<CR>
onoremap <silent> <script> <plug>AngryOuter :call
      \ <SID>ArgCstyle(min([g:angry_max_count, v:count1]))<CR>

vmap <silent> aa <Plug>AngryOuter
omap <silent> aa <Plug>AngryOuter


function! s:ArgCstyle(count, ...)
  let save_sel = @@

  try
    " In visual mode, start searching from the end of the selection.  This way
    " the selection will extend naturally when repeating the text object.
    if a:0 | exe "normal! `>" | endif

    " Find beginning of object and store if it is a comma or opening bracket.
    if searchpair('(', ',', ')', 'bW', "s:IsCursorOnStringOrComment()") <= 0
      return
    endif
    exe "normal! yl"
    let left = @@

    " Find end of object and store if it is a comma or closing bracket.
    if searchpair('(', ',', ')', 'sW', "s:IsCursorOnStringOrComment()") <= 0
      return
    endif
    exe "normal! yl"
    let right = @@

    " Start selection from `' marker which was set by searchpair(), but skip
    " initial comma/bracket and whitespace.
    let cmd = "v`'wo"

    if right == ','
      " Include space after comma at the end of argument.
      let cmd .= "wh"
    else
      " Don't include closing bracket, but include space before argument.  Also
      " include comma before argument if there is one (the alternative is that
      " there is an opening bracket).
      let cmd .= "ho`'" . (left != "," ? "lo" : "o")
    endif

    if a:0
      let [b0,l0,c0,o0] = getpos("'<")
      let [b1,l1,c1,o1] = getpos("''")
      if l0 < l1 || (l0 == l1 && c0 < c1)
        " The old visual area extends further at the beginning than our new
        " visual area does.  Extend the new area to include the old.  This
        " ensures that we can keep extending the visual selection by repeatedly
        " typing command sequence for the text object.
        let cmd .= "o`<o"
      endif
    endif

    exe "normal! ". cmd

  finally
    let @@ = save_sel

    " Repeat the text object if a count was specified.
    if a:count > 1
      " Use 'exe' instead of a plain 'call' to ensure the visual area markers
      " get set the same way as if the text object was typed.
      exe "normal! :\<C-U>call \<SID>ArgCstyle(a:count - 1, visualmode())\<CR>"
    endif
  endtry
endfunction

function! s:IsCursorOnStringOrComment()
   let syn = synIDattr(synID(line("."), col("."), 0), "name")
   return syn =~? "string" || syn =~? "comment"
endfunction
