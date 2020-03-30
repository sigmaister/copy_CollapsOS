( Core words in z80. This requires a full Forth interpreter
  to run, but is also necessary for core.fs. This means that
  it needs to be compiled from a prior bootstrapped binary.

  This stage is tricky due to the fact that references in
  Forth are all absolute, except for prev word refs. This
  means that there are severe limitations to the kind of code
  you can put here.

  You shouldn't define any word with reference to other words.
  This means no regular definition. You can, however, execute
  any word from our high level Forth, as long as it doesn't
  spit word references.

  These restrictions are temporary, I'll figure something out
  so that we can end up fully bootstrap Forth from within
  itself.

  Oh, also: KEY and EMIT are not defined here. There're
  expected to be defined in platform-specific code.
)

( a b c -- b c a )
CODE ROT
    HL POPqq,       ( C )
    DE POPqq,       ( B )
    BC POPqq,       ( A )
    chkPS,
    DE PUSHqq,      ( B )
    HL PUSHqq,      ( C )
    BC PUSHqq,      ( A )
;CODE

( a -- a a )
CODE DUP
    HL POPqq,       ( A )
    chkPS,
    HL PUSHqq,      ( A )
    HL PUSHqq,      ( A )
;CODE

( a -- )
CODE DROP
    HL POPqq,
;CODE

( a b -- b a )
CODE SWAP
    HL POPqq,       ( B )
    DE POPqq,       ( A )
    chkPS,
    HL PUSHqq,      ( B )
    DE PUSHqq,      ( A )
;CODE

( a b -- a b a )
CODE OVER
    HL POPqq,       ( B )
    DE POPqq,       ( A )
    chkPS,
    DE PUSHqq,      ( A )
    HL PUSHqq,      ( B )
    DE PUSHqq,      ( A )
;CODE

( a b -- a b a b )
CODE 2DUP
    HL POPqq,       ( B )
    DE POPqq,       ( A )
    chkPS,
    DE PUSHqq,      ( A )
    HL PUSHqq,      ( B )
    DE PUSHqq,      ( A )
    HL PUSHqq,      ( B )
;CODE

( a b -- )
CODE 2DROP
    HL POPqq,
    HL POPqq,
;CODE

( a b c d -- a b c d a b )

CODE 2OVER
    HL POPqq,       ( D )
    DE POPqq,       ( C )
    BC POPqq,       ( B )
    IY POPqq,       ( A )
    chkPS,
    IY PUSHqq,      ( A )
    BC PUSHqq,      ( B )
    DE PUSHqq,      ( C )
    HL PUSHqq,      ( D )
    IY PUSHqq,      ( A )
    BC PUSHqq,      ( B )
;CODE

( a b c d -- c d a b )

CODE 2SWAP
    HL POPqq,       ( D )
    DE POPqq,       ( C )
    BC POPqq,       ( B )
    IY POPqq,       ( A )
    chkPS,
    DE PUSHqq,      ( C )
    HL PUSHqq,      ( D )
    IY PUSHqq,      ( A )
    BC PUSHqq,      ( B )
;CODE

CODE AND
    HL POPqq,
    DE POPqq,
    chkPS,
    A E LDrr,
    L ANDr,
    L A LDrr,
    A D LDrr,
    H ANDr,
    H A LDrr,
    HL PUSHqq,
;CODE

CODE OR
    HL POPqq,
    DE POPqq,
    chkPS,
    A E LDrr,
    L ORr,
    L A LDrr,
    A D LDrr,
    H ORr,
    H A LDrr,
    HL PUSHqq,
;CODE

CODE XOR
    HL POPqq,
    DE POPqq,
    chkPS,
    A E LDrr,
    L XORr,
    L A LDrr,
    A D LDrr,
    H XORr,
    H A LDrr,
    HL PUSHqq,
;CODE

CODE NOT
    HL POPqq,
    chkPS,
    A L LDrr,
    H ORr,
    HL 0 LDddnn,
    3 JRNZe, ( skip)
    ( false, make 1 )
    HL INCss,
( skip )
    HL PUSHqq,
;CODE

CODE +
    HL POPqq,
    DE POPqq,
    chkPS,
    DE ADDHLss,
    HL PUSHqq,
;CODE

CODE -
    DE POPqq,
    HL POPqq,
    chkPS,
    A ORr,
    DE SBCHLss,
    HL PUSHqq,
;CODE

CODE *
    DE POPqq,
    BC POPqq,
    chkPS,
	( DE * BC -> DE (high) and HL (low) )
    HL 0 LDddnn,
    A 0x10 LDrn,
( loop )
    HL ADDHLss,
    E RLr,
    D RLr,
    6 JRNCe, ( noinc )
    BC ADDHLss,
    3 JRNCe, ( noinc )
    DE INCss,
( noinc )
    A DECr,
    -12 JRNZe, ( loop )
    HL PUSHqq,
;CODE

( Borrowed from http://wikiti.brandonw.net/ )
( Divides AC by DE and places the quotient in AC and the
  remainder in HL )
CODE /MOD
    DE POPqq,
    BC POPqq,
    chkPS,
    A B LDrr,
    B 16 LDrn,
    HL 0 LDddnn,
( loop )
    SCF,
    C RLr,
    RLA,
    HL ADCHLss,
    DE SBCHLss,
    4 JRNCe,  ( skip )
    DE ADDHLss,
    C DECr,
( skip )
    -12 DJNZe, ( loop )
    B A LDrr,
    HL PUSHqq,
    BC PUSHqq,
;CODE

CODE !
    HL POPqq,
    DE POPqq,
    chkPS,
    (HL) E LDrr,
    HL INCss,
    (HL) D LDrr,
;CODE

CODE @
    HL POPqq,
    chkPS,
    E (HL) LDrr,
    HL INCss,
    D (HL) LDrr,
    EXDEHL,
    HL PUSHqq,
;CODE

CODE C!
    HL POPqq,
    DE POPqq,
    chkPS,
    (HL) E LDrr,
;CODE

CODE C@
    HL POPqq,
    chkPS,
    L (HL) LDrr,
    H 0 LDrn,
    HL PUSHqq,
;CODE

CODE PC!
    BC POPqq,
    HL POPqq,
    chkPS,
    L OUT(C)r,
;CODE

CODE PC@
    BC POPqq,
    chkPS,
    H 0 LDrn,
    L INr(C),
    HL PUSHqq,
;CODE

CODE I
    L 0 IX+ LDrIXY,
    H 1 IX+ LDrIXY,
    HL PUSHqq,
;CODE

CODE I'
    L 2 IX- LDrIXY,
    H 1 IX- LDrIXY,
    HL PUSHqq,
;CODE

CODE J
    L 4 IX- LDrIXY,
    H 3 IX- LDrIXY,
    HL PUSHqq,
;CODE

CODE >R
    HL POPqq,
    chkPS,
    ( 17 == pushRS )
    17 CALLnn,
;CODE

CODE R>
    ( 20 == popRS )
    20 CALLnn,
    HL PUSHqq,
;CODE

CODE IMMEDIATE
    CURRENT LDHL(nn),
    HL DECss,
    7 (HL) SETbr,
;CODE

CODE IMMED?
    HL POPqq,
    chkPS,
    HL DECss,
    DE 0 LDddnn,
    7 (HL) BITbr,
    3 JRZe, ( notset )
    DE INCss,
( notset )
    DE PUSHqq,
;CODE

CODE BYE
    HALT,
;CODE

CODE (resSP)
    ( INITIAL_SP == 36 )
    SP 36 @ LDdd(nn),
;CODE

CODE (resRS)
    ( RS_ADDR == 46 )
    IX 46 @ LDddnn,
;CODE

CODE SCMP
    DE  POPqq,
    HL  POPqq,
    chkPS,
    ( 43 == strcmp )
    43 CALLnn,
    ( 40 == flagsToBC )
    40 CALLnn,
    BC PUSHqq,
;CODE

CODE CMP
    HL  POPqq,
    DE  POPqq,
    chkPS,
    A ORr,      ( clear carry )
    DE SBCHLss,
    ( 40 == flagsToBC )
    40 CALLnn,
    BC PUSHqq,
;CODE

CODE (parsed)
    HL POPqq,
    chkPS,
    ( 60 == parseDecimal )
    60 CALLnn,
    10 JRZe, ( success )
    ( error )
    DE 0 LDddnn,
    DE PUSHqq,  ( dummy )
    DE PUSHqq,  ( flag )
    JPNEXT,
( success )
    DE PUSHqq,
    DE 1 LDddnn,
    DE PUSHqq,
;CODE

CODE (find)
    HL POPqq,
    chkPS,
    ( 3 == find )
    3 CALLnn,
    10 JRZe, ( found )
    ( not found )
    HL PUSHqq,
    DE 0 LDddnn,
    DE PUSHqq,
    JPNEXT,
( found )
    DE PUSHqq,
    DE 1 LDddnn,
    DE PUSHqq,
;CODE

CODE SCPY
    HL POPqq,
    chkPS,
    DE HERE LDdd(nn),
    B 0 LDrn,
( loop )
    A (HL) LDrr,
    LD(DE)A,
    HL INCss,
    DE INCss,
    B INCr,
    A ORr,
    -6 JRNZe, ( loop )
    DE A LD(dd)r
    HERE DE LD(nn)dd,
;CODE
