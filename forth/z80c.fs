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
)

( a b c -- b c a )
CODE ROT
    HL POPqq,       ( C )
    DE POPqq,       ( B )
    BC POPqq,       ( A )
    ROUTINE P CALLnn,
    DE PUSHqq,      ( B )
    HL PUSHqq,      ( C )
    BC PUSHqq,      ( A )
;CODE

( a b -- a b a b )
CODE 2DUP
    HL POPqq,       ( B )
    DE POPqq,       ( A )
    ROUTINE P CALLnn,
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
    ROUTINE P CALLnn,
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
    ROUTINE P CALLnn,
    DE PUSHqq,      ( C )
    HL PUSHqq,      ( D )
    IY PUSHqq,      ( A )
    BC PUSHqq,      ( B )
;CODE

