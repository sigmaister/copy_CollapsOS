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

: ABORT _c (resSP) QUIT ;

( This is only the "early parser" in earlier stages. No need
  for an abort message )
: (parse)
    (parsed) NOT IF _c ABORT THEN
;

( a -- )
: (print)
    BEGIN
    DUP         ( a a )
    _c C@       ( a c )
    ( exit if null )
    DUP NOT IF DROP DROP EXIT THEN
    _c EMIT     ( a )
    1 _c +         ( a+1 )
    AGAIN
;

: (uflw)
    LIT< stack-underflow _c (print) _c ABORT
;

: C,
    HERE @ _c C!
    HERE @ 1 _c + HERE !
;

( The NOT is to normalize the negative/positive numbers to 1
  or 0. Hadn't we wanted to normalize, we'd have written:
  32 CMP 1 - )
: WS? 33 _c CMP 1 _c + NOT ;

: TOWORD
    BEGIN
    C< DUP _c WS? NOT IF EXIT THEN DROP
    AGAIN
;

( Read word from C<, copy to WORDBUF, null-terminate, and
  return, make HL point to WORDBUF. )
: WORD
    ( JTBL+30 == WORDBUF )
    [ JTBL 30 + @ LITN ]        ( a )
    _c TOWORD                   ( a c )
    BEGIN
        ( We take advantage of the fact that char MSB is
          always zero to pre-write our null-termination )
        OVER !                  ( a )
        1 _c +                  ( a+1 )
        C<                      ( a c )
        DUP _c WS?
    UNTIL
    ( a this point, PS is: a WS )
    ( null-termination is already written )
    DROP DROP
    [ JTBL 30 + @ LITN ]
;

: LITN
    ( JTBL+24 == NUMBER )
    JTBL 24 _c + ,
    ,
;

: (entry)
    HERE @          ( h )
    _c WORD         ( h s )
    SCPY            ( h )
    ( Adjust HERE -1 because SCPY copies the null )
    HERE @ 1 _c -   ( h h' )
    DUP HERE !      ( h h' )
    SWAP _c -       ( sz )
    ( write prev value )
    HERE @ CURRENT @ _c - ,
    ( write size )
    _c C,
    HERE @ CURRENT !
;

: INTERPRET
    BEGIN
    _c WORD
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

: BOOT
    LIT< (c<$) (find) IF EXECUTE ELSE DROP THEN
    _c INTERPRET
;

( : and ; have to be defined last because it can't be
  executed now also, they can't have their real name
  right away )

: X
    _c (entry)
    ( We cannot use LITN as IMMEDIATE because of bootstrapping
      issues. JTBL+24 == NUMBER JTBL+6 == compiledWord )
    [ JTBL 24 + , JTBL 6 + , ] ,
    BEGIN
    _c WORD
    (find)
    ( is word )
    IF DUP _c IMMED? IF EXECUTE ELSE , THEN
    ( maybe number )
    ELSE (parse*) @ EXECUTE _c LITN THEN
    AGAIN
; IMMEDIATE

: Y
    ['] EXIT ,
    _c R> DROP     ( exit : )
; IMMEDIATE

( Give ":" and ";" their real name )
':' ' X 4 - C!
';' ' Y 4 - C!

