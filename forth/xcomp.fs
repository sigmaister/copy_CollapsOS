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

  Words ":", "IMMEDIATE" and "CODE" are not automatically
  shadowed to allow the harmless inclusion of this unit. This
  shadowing has to take place in your xcomp configuration.

  See example in /emul/forth/xcomp.fs
)

VARIABLE XCURRENT
VARIABLE XOFF

: XCON XCURRENT CURRENT* ! ;
: XCOFF CURRENT CURRENT* ! ;

: (xentry) XCON (entry) XCOFF ;

: XCODE XCON CODE XCOFF ;

: XIMM XCON IMMEDIATE XCOFF ;

: X:
    XCON
    (entry)
    ( 0e == compiledWord )
    [ 0x0e LITN ] ,
    BEGIN
    ( DUP is because we need a copy in case it's IMMED )
    WORD DUP
    (find)      ( w a f )
    IF
        ( is word )
        DUP IMMED?
        IF  ( w a )
            ( When encountering IMMEDIATE, we exec the *host*
              word. )
            DROP    ( w )
            ( hardcoded system CURRENT )
            0x02 RAM+ @ SWAP        ( cur w )
            _find                   ( a f )
            NOT IF ABORT THEN   ( a )
            EXECUTE
        ELSE
            ( not an immed. drop backup w and write, with
              offset. )
            SWAP DROP   ( a )
            DUP 0x100 > IF XOFF @ - THEN
            ,
        THEN
    ELSE ( w a )
        ( maybe number )
        DROP   ( w )
        (parse*) @ EXECUTE LITN
    THEN
    AGAIN
    XCOFF
;
