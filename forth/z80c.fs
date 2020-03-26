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

  ROUTINE stuff is fine. It's not supposed to change.

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
    0 12 - DJNZe, ( loop )
    B A LDrr,
    HL PUSHqq,
    BC PUSHqq,
;CODE

CODE C!
    HL POPqq,
    DE POPqq,
    chkPS,
    E LD(HL)r,
;CODE

CODE C@
    HL POPqq,
    chkPS,
    L LDr(HL),
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
