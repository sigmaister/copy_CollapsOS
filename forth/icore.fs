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
  5. When using words as immediates, make sure that they're
     not defined in icore or, if they are, make sure that
     they contain no "_c" references.

  All these rules make this unit a bit messy, but this is the
  price to pay for the awesomeness of self-bootstrapping.
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

: FLAGS
    ( 52 == FLAGS )
    [ 52 @ LITN ]
;

: (parse*)
    ( 54 == PARSEPTR )
    [ 54 @ LITN ]
;

: HERE
    ( 56 == HERE )
    [ 56 @ LITN ]
;

: CURRENT
    ( 58 == CURRENT )
    [ 58 @ LITN ]
;

: QUIT
    0 _c FLAGS _c ! _c (resRS)
    LIT< INTERPRET (find) _c DROP EXECUTE
;

: ABORT _c (resSP) _c QUIT ;

( This is only the "early parser" in earlier stages. No need
  for an abort message )
: (parse)
    _c (parsed) _c NOT IF _c ABORT THEN
;

( a -- )
: (print)
    BEGIN
    _c DUP      ( a a )
    _c C@       ( a c )
    ( exit if null )
    _c DUP _c NOT IF _c 2DROP EXIT THEN
    _c EMIT     ( a )
    1 _c +         ( a+1 )
    AGAIN
;

: (uflw)
    LIT< stack-underflow _c (print) _c ABORT
;

: C<
    ( 48 == CINPTR )
    [ 48 @ LITN ] _c @ EXECUTE
;

: C,
    _c HERE _c @ _c C!
    _c HERE _c @ 1 _c + _c HERE _c !
;

( The NOT is to normalize the negative/positive numbers to 1
  or 0. Hadn't we wanted to normalize, we'd have written:
  32 CMP 1 - )
: WS? 33 _c CMP 1 _c + _c NOT ;

: TOWORD
    BEGIN
    _c C< _c DUP _c WS? _c NOT IF EXIT THEN _c DROP
    AGAIN
;

( Read word from C<, copy to WORDBUF, null-terminate, and
  return, make HL point to WORDBUF. )
: WORD
    ( 38 == WORDBUF )
    [ 38 @ LITN ]        ( a )
    _c TOWORD                   ( a c )
    BEGIN
        ( We take advantage of the fact that char MSB is
          always zero to pre-write our null-termination )
        _c OVER _c !            ( a )
        1 _c +                  ( a+1 )
        _c C<                   ( a c )
        _c DUP _c WS?
    UNTIL
    ( a this point, PS is: a WS )
    ( null-termination is already written )
    _c 2DROP
    [ 38 @ LITN ]
;

: (entry)
    _c HERE _c @       ( h )
    _c WORD         ( h s )
    SCPY            ( h )
    ( Adjust HERE -1 because SCPY copies the null )
    _c HERE _c @ 1 _c - ( h h' )
    _c DUP _c HERE _c ! ( h h' )
    _c SWAP _c -       ( sz )
    ( write prev value )
    _c HERE _c @ _c CURRENT _c @ _c - ,
    ( write size )
    _c C,
    _c HERE _c @ _c CURRENT _c !
;

: INTERPRET
    BEGIN
    _c WORD
    (find)
    IF
        1 _c FLAGS _c !
        EXECUTE
        0 _c FLAGS _c !
    ELSE
        _c (parse*) _c @ EXECUTE
    THEN
    AGAIN
;

: BOOT
    LIT< (parse) (find) _c DROP _c (parse*) _c !
    LIT< (c<) (find) _c NOT IF LIT< KEY (find) _c DROP THEN
    ( 48 == CINPTR )
    [ 48 @ LITN ] _c !
    LIT< (c<$) (find) IF EXECUTE ELSE _c DROP THEN
    _c INTERPRET
;

( LITN has to be defined after the last immediate usage of
  it to avoid bootstrapping issues )
: LITN
    ( 32 == NUMBER )
    32 , ,
;

( : and ; have to be defined last because it can't be
  executed now also, they can't have their real name
  right away )

: X
    _c (entry)
    ( We cannot use LITN as IMMEDIATE because of bootstrapping
      issues. 32 == NUMBER 14 == compiledWord )
    [ 32 , 14 , ] ,
    BEGIN
    _c WORD
    (find)
    ( is word )
    IF _c DUP _c IMMED? IF EXECUTE ELSE , THEN
    ( maybe number )
    ELSE _c (parse*) _c @ EXECUTE _c LITN THEN
    AGAIN
; IMMEDIATE

: Y
    ['] EXIT ,
    _c R> _c DROP     ( exit : )
; IMMEDIATE

( Give ":" and ";" their real name )
':' ' X 4 - C!
';' ' Y 4 - C!

