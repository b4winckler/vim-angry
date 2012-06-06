" Function argument text objects ('arg' means 'angry' in Swedish)
"
" Author:  Bjorn Winckler <bjorn.winckler@gmail.com>
" Version: 0.1
"
" TODO:
"
"   - List() does not handle 'one item per line' very well
"   - List() does not handle comments properly
"   - Support .
"   - Generalize to arbitrary separators (e.g. ':', '-', ' ', perhaps even
"     general strings) and arbitrary brackets (e.g. '{}', '[]', perhaps even
"     complex strings like '\begin{pmatrix}' and '\end{pmatrix}')
"   - Support empty object (e.g. ',,' and ',/* comment */,')
"   - Growing to last argument no longer works

if exists("loaded_angry") || &cp || v:version < 700 | finish | endif
let loaded_angry = 1


vnoremap <silent> <script> <Plug>AngryOuter
      \ :<C-U>call <SID>ArgCstyle(1, visualmode())<CR>
vnoremap <silent> <script> <Plug>AngryInner
      \ :<C-U>call <SID>ArgCstyle(0, visualmode())<CR>
onoremap <silent> <script> <plug>AngryOuter :call <SID>ArgCstyle(1)<CR>
onoremap <silent> <script> <plug>AngryInner :call <SID>ArgCstyle(0)<CR>

vmap <silent> a, <Plug>AngryOuter
omap <silent> a, <Plug>AngryOuter
vmap <silent> i, <Plug>AngryInner
omap <silent> i, <Plug>AngryInner


vn  <silent> aA :<C-U>call <SID>List('(', ')', ',', 1, 1, visualmode())<CR>
ono <silent> aA :call      <SID>List('(', ')', ',', 1, 1)<CR>
vn  <silent> iA :<C-U>call <SID>List('(', ')', ',', 1, 0, visualmode())<CR>
ono <silent> iA :call      <SID>List('(', ')', ',', 1, 0)<CR>

vn  <silent> aa :<C-U>call <SID>List('(', ')', ',', 0, 1, visualmode())<CR>
ono <silent> aa :call      <SID>List('(', ')', ',', 0, 1)<CR>
vn  <silent> ia :<C-U>call <SID>List('(', ')', ',', 0, 0, visualmode())<CR>
ono <silent> ia :call      <SID>List('(', ')', ',', 0, 0)<CR>

vn  <silent> aL :<C-U>call <SID>List('[[]', ']', ',', 1, 1, visualmode())<CR>
ono <silent> aL :call      <SID>List('[[]', ']', ',', 1, 1)<CR>
vn  <silent> iL :<C-U>call <SID>List('[[]', ']', ',', 1, 0, visualmode())<CR>
ono <silent> iL :call      <SID>List('[[]', ']', ',', 1, 0)<CR>

vn  <silent> al :<C-U>call <SID>List('[[]', ']', ',', 0, 1, visualmode())<CR>
ono <silent> al :call      <SID>List('[[]', ']', ',', 0, 1)<CR>
vn  <silent> il :<C-U>call <SID>List('[[]', ']', ',', 0, 0, visualmode())<CR>
ono <silent> il :call      <SID>List('[[]', ']', ',', 0, 0)<CR>


"
" Select item in a list.
"
" The list is enclosed by brackets given by a:left and a:right (e.g. '(' and
" ')').  Items are separated by a:sep (e.g. ',').
"
" If a:prefix is set, then outer selections include the leftmost separator but
" not the rightmost, and vice versa if a:prefix is not set.
"
" If a:outer is set an outer selection is made (which includes separators).
" If a:outer is not set an inner selection is made (which does not include
" separators on the boundary).  Outer selections are useful for deleting
" items, inner selection are useful for changing items.
"
function! s:List(left, right, sep, prefix, outer, ...)
  let save_mb = getpos("'b")
  let save_unnamed = @"
  let save_ic = &ic
  let &ic = 0
  let times = v:count1 - 1

  try
    " Backward search for separator or unmatched left bracket.
    let flags = a:prefix ? 'bcW' : 'bW'
    if searchpair(a:left, a:sep, a:right, flags,
          \ 's:IsCursorOnStringOrComment()') <= 0
      return
    endif
    exe "normal! ylmb"
    let first = @"

    " Forward search for separator or unmatched right bracket as many times as
    " specified by the command count.
    if searchpair(a:left, a:sep, a:right, 'W',
          \ 's:IsCursorOnStringOrComment()') <= 0
      return
    endif
    exe "normal! yl"
    while times > 0 && @" =~ a:sep && searchpair(a:left, a:sep, a:right, 'W',
          \ 's:IsCursorOnStringOrComment()') > 0
      let times -= 1
      exe "normal! yl"
    endwhile
    let last = @"

    " Build normal command to select visual area.
    " TODO: The below code is incorrect if the selection is too small.
    if a:prefix
      " Select the left separator, but not the right
      let cmd = "\<C-H>v`bo"
      if !a:outer || a:left =~ first
        " Shrink selection on the left
        let cmd .= "olo"
      endif
      if a:outer && a:left =~ first && a:sep =~ last
        " Extend selection on the right
        let cmd .= "l"
      endif
    else
      " Select the right separator, but not the left
      let cmd = "v`blo"
      if !a:outer || a:right =~ last
        " Shrink selection on the right
        let cmd .= "\<C-H>"
      endif
      if a:outer && a:right =~ last && a:sep =~ first
        " Extend selection on the left
        let cmd .= "o\<C-H>o"
      endif
    endif

    if &sel == "exclusive"
      " The last character is not included in the selection when 'sel' is
      " exclusive so extend selection by one character on the right to
      " compensate.  Note that <Space> can go to next line if the cursor is on
      " the end of line, whereas 'l' can't.
      let cmd .= "\<Space>"
    endif

    exe "keepjumps normal! " . cmd
  finally
    call setpos("'b", save_mb)
    let @" = save_unnamed
    let &ic = save_ic
  endtry
endfunction

function! s:ArgCstyle(outer, ...)
  let save_sel = @@
  let save_ma = getpos("'a")
  let save_mb = getpos("'b")
  let nrep = v:count1 - 1

  try
    " Find beginning of object (unless the cursor is on top of a comma or an
    " opening bracket) and store the position in `b.
    exe "normal! ylmb"
    if s:IsCursorOnStringOrComment() || !(@@ == ',' || @@ == '(')
      if searchpair('(', ',', ')', 'bW', 's:IsCursorOnStringOrComment()') <= 0
        return
      endif
      exe "normal! ylmb"
    endif
    " Store whether beginning of object is a comma or an opening bracket.
    let left = @@

    " Skip past whitespace and comments at the start of the object and store
    " position in `a.  (This is a bit of a hack: the '\%0l' pattern never
    " matches, we use searchpair() for its 'skip' argument.)
    call searchpair('\%0l', '', '\S', 'W', 's:IsCursorOnComment()')
    exe "normal! ma"

    " Find end of object.  Note that a match at the cursor position is
    " accepted -- this ensures that a closing bracket won't get skipped past.
    " In visual mode the search starts at the end of the selection so that the
    " selection is extended to the right (just make sure the selection
    " actually ends to the right of the cursor position so that we don't get a
    " 'negative selection').
    if a:0 && s:PosStrictlyOrdered(".", "'>")
      exe "keepjumps normal! `>"
    endif
    if searchpair('(', ',', ')', 'cW', 's:IsCursorOnStringOrComment()') <= 0
      return
    endif
    exe "normal! yl"

    " Keep looking for end of object if a command count was given.  Select as
    " many objects as possible if the command count is larger than the number
    " of objects.
    while nrep > 0 && @@ == ',' &&
          \ searchpair('(', ',', ')', 'W', 's:IsCursorOnStringOrComment()') > 0
      let nrep -= 1
      exe "normal! yl"
    endwhile
    " Store whether end of object is a comma or a closing bracket.
    let right = @@

    if right == ',' && a:outer
      " Skip past whitespace and comments at the end of the object.  (This is
      " a bit of a hack: the '\%0l' pattern never matches, we use searchpair()
      " for its 'skip' argument.)
      call searchpair('\%0l', '', '\S', 'W', 's:IsCursorOnComment()')
    endif

    " Select everything from `a mark to character just before cursor position.
    " Use '^H' instead of plain 'h' in case cursor is in column zero ('h' will
    " not go back a line but '^H' will).
    let cmd = "v`ao\<C-H>"

    if right == ')' && a:outer
      " This is the last object since it ends with a closing bracket.  Include
      " comma before object if there is one.
      let cmd .= "o`b" . (left != "," ? "lo" : "o")
    endif

    exe "keepjumps normal! " . cmd

  finally
    let @@ = save_sel
    call setpos("'a", save_ma)
    call setpos("'b", save_mb)
  endtry
endfunction

function! s:IsCursorOnComment()
   return synIDattr(synID(line("."), col("."), 0), "name") =~? "comment"
endfunction

function! s:IsCursorOnStringOrComment()
   let syn = synIDattr(synID(line("."), col("."), 0), "name")
   return syn =~? "string" || syn =~? "comment"
endfunction

function! s:PosStrictlyOrdered(p0, p1)
  let l0 = getpos(a:p0)
  let l1 = getpos(a:p1)
  return l0[2] < l1[2] || (l0[2] == l1[2] && l0[3] < l1[3])
endfunction
