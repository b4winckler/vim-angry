# Angry text object

This plugin adds text object support for comma-separated arguments enclosed by
brackets.

For example, items in constructs like `(x, y, z)` or `[1, 32, 4]`,
`{ {x, y}, {w, h} }` can be operated on using the objects `aa` (an argument,
includes the separator) or `ia` (inner argument, excludes the separator).  The
text objects support a repeat count and can cope with nested lists, strings and
comments (strings and comments require the current file type to have proper
syntax highlighting support).

There are also upper-case versions `aA` and `iA`.  The lower-case objects will
match at the beginning of an item, whereas the upper-case versions match at the
end of an item.  For example, if the cursor is on the first comma of
`(x, y, z)`, then `daa` will result in `(x, z)` whereas `daA` will result in
`(y, z)`.

The upper-case version includes whitespace and comments after the rightmost
separator, and excludes whitespace and comments before the item.  The
lower-case version includes whitespace and comments before the leftmost
separator, and excludes whitespace and comments after the item.  For example:

    call( x, /* left */ y /* right */, z )

With the cursor on the `y`, typing `daa` results in `call( x /* right */, z )`,
whereas `daA` results in `call( x, /* left */ z )`.


## Examples

Counts are supported, so e.g. `d3a,` will turn

    function(a, 33, Rstyle="calls, with commas inside strings, are OK")

into `function()`.  Note that commas inside strings are ignored and so are
comments (this feature depends on the syntax highlighting to detect strings and
comments so `'filetype'` must be set properly for this to work).

If the cursor is on the `R` in the above function call, then `da,` results in
`function(a, 33)` so the comma after `33` is properly deleted.


## Installation

Assuming you are using the
[Pathogen plugin](https://github.com/tpope/vim-pathogen),
just clone this repository in your `~/.vim/bundle` folder like so:

```
$ cd ~/.vim/bundle
$ git clone https://github.com/b4winckler/vim-angry.git
```

Alternatively, you can just put the `angry.vim` script in your
`~/.vim/plugin` folder (create the folder if it does not already exist).


## Deficiencies

-   Repeating the last `daa` (for example) with `.` does not work.
-   Growing the selection in visual mode by repeatedly entering the text object
    is currently not supported.
-   Mismatched brackets are not handled.
-   Using the text objects outside a bracket-enclosed list can have unexpected
    consequences.
-   Empty arguments are not handled properly.

## License

Copyright 2012 Björn Winckler.  Distributed under the same license as Vim
itself.  See `:h license`.
