[![Build Status](https://travis-ci.org/iskolbin/lbase64.svg?branch=master)](https://travis-ci.org/iskolbin/lwcwidth)
[![license](https://img.shields.io/badge/license-public%20domain-blue.svg)]()

Lua wcwidth implementation
==========================

Pure Lua implementation of [wcwidth](http://man7.org/linux/man-pages/man3/wcwidth.3.html)
function. This function determines the number of column positions required for the character to
display. The value passed must be a character code.

```lua
local wcwidth = require 'wcwidth'
print( wcwidth( 0 ))      -- prints 0
print( wcwidth( 32 ))     -- prints 1, ASCII space
print( wcwidth( 0x0410 )) -- prints 1, cyrillic "A"
print( wcwidth( 0x30b3 )) -- prints 2, katakana "コ"
```

wcwidth( wc )
-------------
The function either returns `0` (if `wc` is a null wide-character code), or
returns the number of column positions to be occupied by the wide-character
code `wc`, or returns `−1` (if wc does not correspond to a printing
wide-character code)
