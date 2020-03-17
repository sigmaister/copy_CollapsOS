: H HERE @ ;
: -^ SWAP - ;
: +! SWAP OVER @ + SWAP ! ;
: ALLOT HERE +! ;
: , H ! 2 ALLOT ;
: C, H C! 1 ALLOT ;
: BEGIN H ; IMMEDIATE
: COMPILE ' ['] LITN EXECUTE ['] , , ; IMMEDIATE
: AGAIN COMPILE (bbr) H -^ C, ; IMMEDIATE
: NOT 1 SWAP SKIP? EXIT 0 * ;
: ( BEGIN LITS ) WORD SCMP NOT SKIP? AGAIN ; IMMEDIATE
( Hello, hello, krkrkrkr... do you hear me?
  Ah, voice at last! Some lines above need comments
  BTW: Forth lines limited to 64 cols because of default
  input buffer size in Collapse OS

  COMPILE; Tough one. Get addr of caller word (example above
  (bbr)) and then call LITN on it. However, LITN is an
  immediate and has to be indirectly executed. Then, write
  a reference to "," so that this word is written to HERE.
 
  NOT: a bit convulted because we don't have IF yet )
: IF COMPILE SKIP? COMPILE (fbr) H 1 ALLOT ; IMMEDIATE
( Subtract TOS from H to get offset to write to IF or ELSE's
  br cell )
: THEN DUP H -^ SWAP C! ; IMMEDIATE
( write (fbr) addr, allot, then same as THEN )
: ELSE
    COMPILE (fbr) 1 ALLOT DUP H -^ SWAP C! H 1 - ; IMMEDIATE
: ? @ . ;
: VARIABLE CREATE 2 ALLOT ;
: CONSTANT CREATE H ! DOES> @ ;
: = CMP NOT ;
: < CMP 0 1 - = ;
: > CMP 1 = ;
