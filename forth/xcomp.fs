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

  Words overrides like ":", "IMMEDIATE" and "CODE" are not
  automatically shadowed to allow the harmless inclusion of
  this unit. This shadowing has to take place in your xcomp
  configuration.

  See example in /emul/forth/xcomp.fs

  Note that this cross compilation unit is far from foolproof
  and cannot cross compile any kind of code. Cross compliation
  of Forth dicts is *tricky*. This unit is designed to cross
  compile the core full interpreter, that is, the contents
  of the "/forth" folder of the project.

  Cross compiling anything else might work, but as soon as
  you start defining immediates and using them on-the-fly,
  things get icky.
)

VARIABLE XCURRENT
VARIABLE XOFF

: XCON XCURRENT CURRENT* ! ;
: XCOFF 0x02 RAM+ CURRENT* ! ;

: (xentry) XCON (entry) XCOFF ;

: XCODE XCON CODE XCOFF ;

: XIMM XCON IMMEDIATE XCOFF ;

: XAPPLY
    DUP XOFF @ > IF XOFF @ - THEN
;

( Run find in XCURRENT and apply XOFF )
: (xfind)
    XCURRENT @ SWAP     ( xcur w )
    _find               ( a f )
    IF  ( a )
        ( apply XOFF )
        XAPPLY 1
    ELSE
        0
    THEN
;

: X' XCON ' XCOFF XAPPLY ;
: X['] X' LITN ;
( TODO: am I making the word "," stable here? )
: XCOMPILE X' LITN ['] , , ;

: X:
    (xentry)
    ( 0e == compiledWord )
    [ 0x0e LITN ] ,
    BEGIN
    ( DUP is because we need a copy in case it's IMMED )
    WORD DUP
    ( cross compile CURRENT )
    XCURRENT @ SWAP     ( w xcur w )
    _find               ( w a f )
    IF
        ( is word )
        DUP IMMED?
        IF  ( w a )
            ( When encountering IMMEDIATE, we exec the *host*
              word. )
            DROP    ( w )
            ( system CURRENT )
            0x02 RAM+ @ SWAP        ( cur w )
            _find                   ( a f )
            NOT IF ABORT THEN   ( a )
            XCON EXECUTE XCOFF
        ELSE
            ( not an immed. drop backup w and write, with
              offset. )
            SWAP DROP   ( a )
            XAPPLY
            ,
        THEN
    ELSE ( w a )
        ( maybe number )
        DROP   ( w )
        (parse*) @ EXECUTE LITN
    THEN
    AGAIN
;
