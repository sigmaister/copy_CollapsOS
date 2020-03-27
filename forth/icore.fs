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

  Also note that because of that "_c" mechanism, it might
  take two rounds of bootstrapping before the compiled
  z80c.bin file is "stabilized". That's because the 2nd time
  around, the recorded offset will have changed.
)

: _c
    [
    ' ROT
    6 -         ( header )
    ' _bend
    -           ( our offset )
    LITN
    ]
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

( This is only the "early parser" in earlier stages. No need
  for an abort message )
: (parse)
    (parsed) SKIP? ABORT
;

( a -- )
: (print)
    BEGIN
    DUP         ( a a )
    _c C@       ( a c )
    ( exit if null )
    DUP NOT IF DROP DROP EXIT THEN
    EMIT        ( a )
    1 +         ( a+1 )
    AGAIN
;

: (entry)
    HERE @          ( h )
    WORD            ( h s )
    SCPY            ( h )
    ( Adjust HERE -1 because SCPY copies the null )
    HERE @ 1 _c -   ( h h' )
    DUP HERE !      ( h h' )
    SWAP _c -       ( sz )
    ( write prev value )
    HERE @ CURRENT @ _c - ,
    ( write size )
    C,
    HERE @ CURRENT !
;

( : and ; have to be defined last because it can't be
  executed now also, they can't have their real name
  right away )

: X
    _c (entry)
    ( JUMPTBL+0 == compiledWord )
    [ ROUTINE J LITN ] ,
    BEGIN
    WORD
    (find)
    ( is word )
    IF DUP IMMED? IF EXECUTE ELSE , THEN
    ( maybe number )
    ELSE (parse*) @ EXECUTE LITN THEN
    AGAIN
; IMMEDIATE

: Y
    ['] EXIT ,
    _c R> DROP     ( exit : )
; IMMEDIATE

( Give ":" and ";" their real name )
':' ' X 4 - C!
';' ' Y 4 - C!

