" Text objects for function arguments ('arg' means 'angry' in Swedish) and
" other items surrounded by brackets and separated by commas.
"
" Author:  Bjorn Winckler <bjorn.winckler@gmail.com>
" Version: 0.1
"
" TODO:
"
" - Growing selection in visual mode does not work
" - 'One item per line' is not handled very well
" - Comments are not handled properly (difficult to accomodate all styles,
"   e.g. comment after argument, comment on line above argument, ...)
" - Support .
" - Support empty object (e.g. ',,' and ',/* comment */,')
" - Generalize to arbitrary separators (e.g. ':', '-', ' ', perhaps even
"   general strings)
" - Generalize to arbitrary brackets (e.g. complex strings like
"   '\begin{pmatrix}' and '\end{pmatrix}')

if exists("loaded_angry") || &cp || v:version < 700 | finish | endif
let loaded_angry = 1

"
" Map to text objects aa (An Argument) and ia (Inner Argument) unless
" disabled.
"
" The objects aA and iA are similar to aa and ia, except aA and iA match at
" closing brackets, whereas aa and ia match at opening brackets and commas.
" Generally, the lowercase versions match to the right and the uppercase
" versions match to the left of the cursor.
"
if !exists("g:angry_disable_maps")
  vmap <silent> aa <Plug>AngryOuterPrefix
  omap <silent> aa <Plug>AngryOuterPrefix
  vmap <silent> ia <Plug>AngryInnerPrefix
  omap <silent> ia <Plug>AngryInnerPrefix

  vmap <silent> aA <Plug>AngryOuterSuffix
  omap <silent> aA <Plug>AngryOuterSuffix
  vmap <silent> iA <Plug>AngryInnerSuffix
  omap <silent> iA <Plug>AngryInnerSuffix
endif

"
" Specify which patterns to be used to find left and right brackets.
"
" TODO: This should probably be determined on a per-buffer (or filetype) basis.
"
if !exists('g:angry_brackets')
  let g:angry_brackets = ['[[({]', '[])}]']
endif

"
" Specify which separator to use.
"
" TODO: This should probably be determined on a per-buffer (or filetype) basis.
"
if !exists('g:angry_separator')
  let g:angry_separator = ','
endif


vnoremap <silent> <script> <Plug>AngryOuterPrefix :<C-U>call
      \ <SID>List(g:angry_brackets[0], g:angry_brackets[1], g:angry_separator,
      \           1, 1, v:count1, visualmode())<CR>
vnoremap <silent> <script> <Plug>AngryOuterSuffix :<C-U>call
      \ <SID>List(g:angry_brackets[0], g:angry_brackets[1], g:angry_separator,
      \           0, 1, v:count1, visualmode())<CR>
vnoremap <silent> <script> <Plug>AngryInnerPrefix :<C-U>call
      \ <SID>List(g:angry_brackets[0], g:angry_brackets[1], g:angry_separator,
      \           1, 0, v:count1, visualmode())<CR>
vnoremap <silent> <script> <Plug>AngryInnerSuffix :<C-U>call
      \ <SID>List(g:angry_brackets[0], g:angry_brackets[1], g:angry_separator,
      \           0, 0, v:count1, visualmode())<CR>

onoremap <silent> <script> <Plug>AngryOuterPrefix :call
      \ <SID>List(g:angry_brackets[0], g:angry_brackets[1], g:angry_separator,
      \           1, 1, v:count1)<CR>
onoremap <silent> <script> <Plug>AngryOuterSuffix :call
      \ <SID>List(g:angry_brackets[0], g:angry_brackets[1], g:angry_separator,
      \           0, 1, v:count1)<CR>
onoremap <silent> <script> <Plug>AngryInnerPrefix :call
      \ <SID>List(g:angry_brackets[0], g:angry_brackets[1], g:angry_separator,
      \           1, 0, v:count1)<CR>
onoremap <silent> <script> <Plug>AngryInnerSuffix :call
      \ <SID>List(g:angry_brackets[0], g:angry_brackets[1], g:angry_separator,
      \           0, 0, v:count1)<CR>


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
function! s:List(left, right, sep, prefix, outer, times, ...)
  let save_mb = getpos("'b")
  let save_unnamed = @"
  let save_ic = &ic
  let &ic = 0

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
    let times = a:times - 1
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
    if a:0 > 0 && s:PosStrictlyOrdered(".", "'>")
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
