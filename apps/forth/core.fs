: H HERE @ ;
: -^ SWAP - ;
: +! SWAP OVER @ + SWAP ! ;
: ALLOT HERE +! ;
: C, H C! 1 ALLOT ;
: COMPILE ' ['] LITN EXECUTE ['] , , ; IMMEDIATE
: BEGIN H ; IMMEDIATE
: AGAIN COMPILE (bbr) H -^ C, ; IMMEDIATE
: UNTIL COMPILE SKIP? COMPILE (bbr) H -^ C, ; IMMEDIATE
: NOT 1 SWAP SKIP? EXIT 0 * ;
: ( BEGIN LITS ) WORD SCMP NOT UNTIL ; IMMEDIATE
( Hello, hello, krkrkrkr... do you hear me?
  Ah, voice at last! Some lines above need comments
  BTW: Forth lines limited to 64 cols because of default
  input buffer size in Collapse OS

  COMPILE; Tough one. Get addr of caller word (example above
  (bbr)) and then call LITN on it. However, LITN is an
  immediate and has to be indirectly executed. Then, write
  a reference to "," so that this word is written to HERE.

  NOT: a bit convulted because we don't have IF yet )

: IF                ( -- a | a: br cell addr )
    COMPILE SKIP?   ( if true, don't branch )
    COMPILE (fbr)
    H               ( push a )
    1 ALLOT         ( br cell allot )
; IMMEDIATE

: THEN              ( a -- | a: br cell addr )
    DUP H -^ SWAP   ( a-H a )
    C!
; IMMEDIATE

: ELSE              ( a1 -- a2 | a1: IF cell a2: ELSE cell )
    COMPILE (fbr)
    1 ALLOT
    DUP H -^ SWAP   ( a-H a )
    C!
    H 1 -           ( push a. -1 for allot offset )
; IMMEDIATE

: ? @ . ;
: VARIABLE CREATE 2 ALLOT ;
: CONSTANT CREATE H ! DOES> @ ;
: = CMP NOT ;
: < CMP 0 1 - = ;
: > CMP 1 = ;
: / /MOD SWAP DROP ;
: MOD /MOD DROP ;
