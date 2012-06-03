" Function argument text objects ('arg' means 'angry' in Swedish)
" Author:  Bjorn Winckler <bjorn.winckler@gmail.com>
" Version: 0.1

if exists("loaded_angry") || &cp || v:version < 700
  finish
endif
" let loaded_angry = 1


vnoremap <silent> <script> <Plug>AngryOuter
      \ :<C-U>call <SID>ArgCstyle(visualmode())<CR>
onoremap <silent> <script> <plug>AngryOuter :call <SID>ArgCstyle()<CR>

vmap <silent> a, <Plug>AngryOuter
omap <silent> a, <Plug>AngryOuter


function! s:ArgCstyle(...)
  let save_sel = @@
  let save_mprime = getpos("''")
  let save_ma = getpos("'a")
  let nrep = v:count1 - 1

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

    " Skip past whitespace and comments at the start of the object.  (This is
    " a bit of a hack: the '\%0l' pattern never matches, we use searchpair()
    " for its 'skip' argument.)
    call searchpair('\%0l', '', '\S', 'sW', 's:IsCursorOnStringOrComment()')
    exe "normal! ma"

    " Find end of object and store if it is a comma or closing bracket.  The
    " loop takes the command count into account.  Select as many text objects
    " as possible if the command count is larger than the number of objects.
    if searchpair('(', ',', ')', 'W', "s:IsCursorOnStringOrComment()") <= 0
      return
    endif
    exe "normal! yl"
    while nrep > 0 && @@ == ',' &&
          \ searchpair('(', ',', ')', 'W', "s:IsCursorOnStringOrComment()") > 0
      let nrep -= 1
      exe "normal! yl"
    endwhile
    let right = @@

    " Start selection from `a mark.
    let cmd = "v`ao"

    if right == ','
      " Include whitespace and comments at the end of the object.  (This is a
      " bit of a hack: the '\%0l' pattern never matches, we use searchpair()
      " for its 'skip' argument.)
      call searchpair('\%0l', '', '\S', 'W', 's:IsCursorOnStringOrComment()')
      let cmd .= 'h'
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
    call setpos("'a", save_ma)
    call setpos("''", save_mprime)
  endtry
endfunction

function! s:IsCursorOnStringOrComment()
   let syn = synIDattr(synID(line("."), col("."), 0), "name")
   return syn =~? "string" || syn =~? "comment"
endfunction
