( Inner core. This unit represents core definitions that
  happen right after native definitions. Before core.fs.

  Unlike core.fs and its followers, this unit isn't self-
  sustained. Like native defs it uses the machinery of a
  full Forth interpreter, notably for flow structures.

  Because of that, it has to obey specific rules:

  1. It cannot compile a word from higher layers. Using
     immediates is fine though.
  2. If it references a word from this unit or from native
     definitions, these need to be properly offsetted
     because their offset at compile time are not the same
     as their runtime offsets.
  3. Anything they refer to in the boot binary has to be
     properly stabilized.
  4. Make sure that the words you compile are not overridden
     by the full interpreter.
)

( When referencing words from native defs or this very unit,
  use this compiling word, which subtract the proper offset
  from the compiled word. That proper offset is:
  1. Take ROT-header addr, the first native def.
  2. Subtract _bend, boot's last word.
  3. That will give us the offset to subtract to get the addr
     of our word at runtime.

  This means, of course, that any word compiling a _c word
  can't be executed immediately.
)

: _c
    ['] ROT
    6 -         ( header )
    ['] _bend
    -           ( our offset )
    '           ( get word )
    -^          ( apply offset )
    ,           ( write! )
; IMMEDIATE

: INTERPRET
    BEGIN
    WORD
    (find)
    IF
        1 FLAGS !
        EXECUTE
        0 FLAGS !
    ELSE
        (parse*) @ EXECUTE
    THEN
    AGAIN
;

( ; has to be defined last because it can't be executed now )
: X             ( can't have its real name now )
    ['] EXIT ,
    _c R> DROP     ( exit COMPILE )
    _c R> DROP     ( exit : )
; IMMEDIATE

( Give ";" its real name )
';' CURRENT @ 4 - C!

