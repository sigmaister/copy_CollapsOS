: H HERE @ ;
: -^ SWAP - ;
: +! SWAP OVER @ + SWAP ! ;
: ALLOT HERE +! ;
: , H ! 2 ALLOT ;
: C, H C! 1 ALLOT ;
: IF ['] (fbr?) , H 1 ALLOT ; IMMEDIATE
: THEN DUP H -^ SWAP C! ; IMMEDIATE
: ELSE ['] (fbr) , 1 ALLOT DUP H -^ SWAP C! H 1 - ; IMMEDIATE
: RECURSE R> R> 2 - >R >R EXIT ;
: ( LIT@ ) WORD SCMP IF RECURSE THEN ; IMMEDIATE
( Hello, hello, krkrkrkr... do you hear me? )
( Ah, voice at last! Some lines above need comments )
( IF: write (fbr?) addr, push HERE, create cell )
( THEN: Subtract TOS from H to get offset to write to cell )
( in that same TOS's addr )
( ELSE: write (fbr) addr, allot, then same as THEN )
( RECURSE: RS TOS is for RECURSE itself, then we have to dig )
( one more level to get to RECURSE's parent's caller. )
: NOT IF 0 ELSE 1 THEN ;
: ? @ . ;
: VARIABLE CREATE 2 ALLOT ;
: CONSTANT CREATE H ! DOES> @ ;
: = CMP NOT ;
: < CMP 0 1 - = ;
: > CMP 1 = ;
