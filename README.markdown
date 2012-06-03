# Angry text object

This plugin adds support for a *function argument* text object.  The object is
by default bound to `a,` and it behaves in a predictable and natural manner
that is specially crafted for C-style function arguments.  By "C-style" is
meant arguments which are delimited by parenthesis and separated by commas
(hence the choice of `a,` for the default binding).

## Examples

Counts are supported, so e.g. `d3a,` will turn

    function(a, 33, Rstyle="calls, with commas inside strings, are OK")

into `function()`.  Note that commas inside strings are ignored and so are
comments (this feature depends on the syntax highlighting to detect strings and
comments so `'filetype'` must be set properly for this to work).

If the cursor is on the `R` in the above function call, then `da,` results in
`function(a, 33)` so the comma after `33` is properly deleted.

It is also possible to incrementally extend the selection in visual mode.  If
the cursor is on the first parameter `a` and you hit `va,` then `a, ` is
selected.  Hit `,a` again and the selection grows to `a, 33, `.

Similarly, assume the cursor is on one of the `3` then hit `va,` and the
selection becomes `33, `.  Hit `,a` again and the selection grows `, 33, ..`
all the way up to the closing parenthesis.

## Installation

Assuming you are using the
[Pathogen plugin](https://github.com/tpope/vim-pathogen),
just clone this repository in your `~/.vim/bundle` folder like so:

```
$ cd ~/.vim/bundle
$ git clone https://github.com/b4winckler/vim-angry.git
```

Alternatively, you can just put the `angry.vim` script in your
`~/.vim/plugin` folder.
