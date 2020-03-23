( When building a compiled dict, always include this unit at
  the end of it so that Forth knows how to hook LATEST into
  it )
WORD _______ (entry)

( After each dummy word like this, we poke IO port 2 with our
  current HERE value. The staging executable needs it to know
  what to dump. )

HERE @ 256 / 2 PC!
HERE @ 2 PC!
