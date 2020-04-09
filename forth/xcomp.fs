( Do dictionary cross compilation.
  Include this file right before your cross compilation, then
  set XCURRENT to CURRENT and XOFF to H@ - your target hook.
  Example: H@ ' _bend - XOFF !

  This redefines defining words to achieve cross compilation.
  The goal is two-fold:

  1. Add an offset to all word references in definitions.
  2. Don't shadow important words we need right now.

  New defining words establish a new XCURRENT, a copy of
  CURRENT. From now on, CURRENT doesn't move. This means that
  "'" and friends will *not* find words you're about to
  define. Only (xfind) will.

  Words ":", "IMMEDIATE" and ":" are not automatically
  shadowed to allow the harmless inclusion of this unit. This
  shadowing has to take place in your xcomp configuration.

  See example in /emul/forth/xcomp.fs
)

VARIABLE XCURRENT
VARIABLE XOFF

: (xentry)
    H@           ( h )
    WORD         ( h s )
    SCPY         ( h )
    ( Adjust HERE -1 because SCPY copies the null )
    H@ 1 -       ( h h' )
    DUP HERE !   ( h h' )
    -^           ( sz )
    ( write prev value )
    H@ XCURRENT @ - ,
    ( write size )
    C,
    H@ XCURRENT !
;

( Finds in *both* CURRENT and XCURRENT )
( w -- a f xa xf )
: (xfind)
    DUP                     ( w w )
    CURRENT @ SWAP          ( w cur w )
    _find                   ( w a f )
    ROT                     ( a f w )
    XCURRENT @ SWAP         ( a f xcur w )
    _find                   ( a f xa xf )
;

: XCODE
    (xentry) 23 ,
;

: XIMM
    XCURRENT @ 1 -
    DUP C@ 128 OR SWAP C!
;

: X:
    (xentry)
    ( 0e == compiledWord )
    [ 0x0e LITN ] ,
    BEGIN
    WORD
    (xfind)
    IF  ( a f xa )
        ( is word )
        DUP IMMED?
        IF  ( a f xa )
            ( When encountering IMMEDIATE, we exec the *host*
              word. )
            DROP    ( a f )
            NOT IF ABORT THEN   ( a )
            EXECUTE
        ELSE
            ( when compiling, we don't care about the host
              find. )
            DUP 0x100 > IF XOFF @ - THEN
            , 2DROP
        THEN
    ELSE ( w f xa )
        ( maybe number )
        2DROP   ( w )
        (parse*) @ EXECUTE LITN
    THEN
    AGAIN
;
