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
    LIT< INTERPRET _c (find) _c DROP EXECUTE
;

: ABORT _c (resSP) _c QUIT ;

: = _c CMP _c NOT ;
: < _c CMP -1 _c = ;
: > _c CMP 1 _c = ;

: (parsed)      ( a -- n f )
    ( read first char outside of the loop. it *has* to be
      nonzero. )
    _c DUP _c C@                    ( a c )
    _c DUP _c NOT IF EXIT THEN      ( a 0 )
    ( special case: do we have a negative? )
    _c DUP '-' _c = IF
        ( Oh, a negative, let's recurse and reverse )
        _c DROP 1 _c +                  ( a+1 )
        _c (parsed)                     ( n f )
        _c SWAP 0 _c SWAP               ( f 0 n )
        _c - _c SWAP EXIT               ( 0-n f )
    THEN
    ( running result, staring at zero )
    0 _c SWAP                               ( a r c )
    ( Loop over chars )
    BEGIN
    ( parse char )
    '0' _c -
    ( if bad, return "a 0" )
    _c DUP 0 _c < IF _c 2DROP 0 EXIT THEN   ( bad )
    _c DUP 9 _c > IF _c 2DROP 0 EXIT THEN   ( bad )
    ( good, add to running result )
    _c SWAP 10 _c * _c +                    ( a r*10+n )
    _c SWAP 1 _c + _c SWAP                  ( a+1 r )
    ( read next char )
    _c OVER _c C@
    _c DUP _c NOT UNTIL
    ( we're done and it's a success. We have "a r c", we want
      "r 1". )
    _c DROP _c SWAP _c DROP 1
;

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

: ,
    _c HERE _c @ _c !
    _c HERE _c @ 2 _c + _c HERE _c !
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
    _c HERE _c @    ( h )
    _c WORD         ( h s )
    _c SCPY         ( h )
    ( Adjust HERE -1 because SCPY copies the null )
    _c HERE _c @ 1 _c - ( h h' )
    _c DUP _c HERE _c ! ( h h' )
    _c SWAP _c -       ( sz )
    ( write prev value )
    _c HERE _c @ _c CURRENT _c @ _c - _c ,
    ( write size )
    _c C,
    _c HERE _c @ _c CURRENT _c !
;

: INTERPRET
    BEGIN
    _c WORD
    _c (find)
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
    LIT< (parse) _c (find) _c DROP _c (parse*) _c !
    LIT< (c<) _c (find) _c
    NOT IF LIT< KEY _c (find) _c DROP THEN
    ( 48 == CINPTR )
    [ 48 @ LITN ] _c !
    LIT< (c<$) _c (find) IF EXECUTE ELSE _c DROP THEN
    _c INTERPRET
;

( LITN has to be defined after the last immediate usage of
  it to avoid bootstrapping issues )
: LITN
    ( 32 == NUMBER )
    32 _c , _c ,
;

( : and ; have to be defined last because it can't be
  executed now also, they can't have their real name
  right away )

: X
    _c (entry)
    ( We cannot use LITN as IMMEDIATE because of bootstrapping
      issues. Same thing for ",".
      32 == NUMBER 14 == compiledWord )
    [ 32 H@ ! 2 ALLOT 14 H@ ! 2 ALLOT ] _c ,
    BEGIN
    _c WORD
    _c (find)
    ( is word )
    IF _c DUP _c IMMED? IF EXECUTE ELSE _c , THEN
    ( maybe number )
    ELSE _c (parse*) _c @ EXECUTE _c LITN THEN
    AGAIN
; IMMEDIATE

: Y
    ['] EXIT _c ,
    _c R> _c DROP     ( exit : )
; IMMEDIATE

( Give ":" and ";" their real name )
':' ' X 4 - C!
';' ' Y 4 - C!

