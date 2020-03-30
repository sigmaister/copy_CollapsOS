: H@ HERE @ ;
: -^ SWAP - ;
: [ INTERPRET 1 FLAGS ! ; IMMEDIATE
: ] R> DROP ;
: LIT 34 , ;
: LITS LIT SCPY ;
: LIT< WORD LITS ; IMMEDIATE
: _err LIT< word-not-found (print) ABORT ;
: ' WORD (find) NOT (?br) [ 4 , ] _err ;
: ['] ' LITN ; IMMEDIATE
: COMPILE ' LITN ['] , , ; IMMEDIATE
: [COMPILE] ' , ; IMMEDIATE
: BEGIN H@ ; IMMEDIATE
: AGAIN COMPILE (br) H@ - , ; IMMEDIATE
: UNTIL COMPILE (?br) H@ - , ; IMMEDIATE
: ( BEGIN LIT< ) WORD SCMP NOT UNTIL ; IMMEDIATE
( Hello, hello, krkrkrkr... do you hear me?
  Ah, voice at last! Some lines above need comments
  BTW: Forth lines limited to 64 cols because of default
  input buffer size in Collapse OS

  "_": words starting with "_" are meant to be "private",
  that is, only used by their immediate surrondings.

  LIT: 34 == LIT
  COMPILE: Tough one. Get addr of caller word (example above
  (br)) and then call LITN on it. )

: +! SWAP OVER @ + SWAP ! ;
: ALLOT HERE +! ;

: IF                ( -- a | a: br cell addr )
    COMPILE (?br)
    H@              ( push a )
    2 ALLOT         ( br cell allot )
; IMMEDIATE

: THEN              ( a -- | a: br cell addr )
    DUP H@ -^ SWAP   ( a-H a )
    !
; IMMEDIATE

: ELSE              ( a1 -- a2 | a1: IF cell a2: ELSE cell )
    COMPILE (br)
    2 ALLOT
    DUP H@ -^ SWAP  ( a-H a )
    !
    H@ 2 -          ( push a. -2 for allot offset )
; IMMEDIATE

: CREATE
    (entry)            ( empty header with name )
    11                 ( 11 == cellWord )
    ,                  ( write it )
;

( We run this when we're in an entry creation context. Many
  things we need to do.
  1. Change the code link to doesWord
  2. Leave 2 bytes for regular cell variable.
  3. Write down RS' RTOS to entry.
  4. exit parent definition
)
: DOES>
    ( Overwrite cellWord in CURRENT )
    ( 63 == doesWord )
    63 CURRENT @ !
    ( When we have a DOES>, we forcefully place HERE to 4
      bytes after CURRENT. This allows a DOES word to use ","
      and "C," without messing everything up. )
    CURRENT @ 4 + HERE !
    ( HERE points to where we should write R> )
    R> ,
    ( We're done. Because we've popped RS, we'll exit parent
      definition )
;

: VARIABLE CREATE 2 ALLOT ;
: CONSTANT CREATE , DOES> @ ;
: = CMP NOT ;
: < CMP 0 1 - = ;
: > CMP 1 = ;
: / /MOD SWAP DROP ;
: MOD /MOD DROP ;

( In addition to pushing H@ this compiles 2 >R so that loop
  variables are sent to PS at runtime )
: DO
    COMPILE SWAP COMPILE >R COMPILE >R
    H@
; IMMEDIATE

( One could think that we should have a sub word to avoid all
  these COMPILE, but we can't because otherwise it messes with
  the RS )
: LOOP
    COMPILE R> 1 LITN COMPILE + COMPILE DUP COMPILE >R
    COMPILE I' COMPILE = COMPILE (?br)
    H@ - ,
    COMPILE R> COMPILE DROP COMPILE R> COMPILE DROP
; IMMEDIATE

( WARNING: there are no limit checks. We must be cautious, in
  core code, not to create more than SYSV_BUFSIZE/2 sys vars.
  Also: SYSV shouldn't be used during runtime: SYSVNXT won't
  point at the right place. It should only be used during
  stage1 compilation. This is why this word is not documented
  in dictionary.txt )

: (sysv)
    (entry)
    ( 8 == sysvarWord )
    8 ,
    ( 50 == SYSVNXT )
    [ 50 @ LITN ] DUP    ( a a )
    ( Get new sysv addr )
    @ ,                         ( a )
    ( increase current sysv counter )
    2 SWAP +!
;

: ."
    LIT
    BEGIN
        C< DUP          ( c c )
        ( 34 is ASCII for " )
        DUP 34 = IF DROP DROP 0 0 THEN
        C,
    0 = UNTIL
    COMPILE (print)
; IMMEDIATE

: ABORT" [COMPILE] ." COMPILE ABORT ; IMMEDIATE
