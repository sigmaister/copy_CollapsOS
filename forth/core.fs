: H@ HERE @ ;
: -^ SWAP - ;
: [LITN] LITN ; IMMEDIATE
: LIT ROUTINE S [LITN] , ;
: LITS LIT SCPY ;
: LIT< WORD LITS ; IMMEDIATE
: _err LIT< word-not-found (print) ABORT ;
: ' WORD (find) SKIP? _err ;
: ['] WORD (find) SKIP? _err LITN ; IMMEDIATE
: COMPILE ' LITN ['] , , ; IMMEDIATE
: [COMPILE] ' , ; IMMEDIATE
: BEGIN H@ ; IMMEDIATE
: AGAIN COMPILE (bbr) H@ -^ C, ; IMMEDIATE
: UNTIL COMPILE SKIP? COMPILE (bbr) H@ -^ C, ; IMMEDIATE
: ( BEGIN LIT< ) WORD SCMP NOT UNTIL ; IMMEDIATE
( Hello, hello, krkrkrkr... do you hear me?
  Ah, voice at last! Some lines above need comments
  BTW: Forth lines limited to 64 cols because of default
  input buffer size in Collapse OS

  "_": words starting with "_" are meant to be "private",
  that is, only used by their immediate surrondings.

  COMPILE: Tough one. Get addr of caller word (example above
  (bbr)) and then call LITN on it. )

: +! SWAP OVER @ + SWAP ! ;
: ALLOT HERE +! ;

: IF                ( -- a | a: br cell addr )
    COMPILE SKIP?   ( if true, don't branch )
    COMPILE (fbr)
    H@              ( push a )
    1 ALLOT         ( br cell allot )
; IMMEDIATE

: THEN              ( a -- | a: br cell addr )
    DUP H@ -^ SWAP   ( a-H a )
    C!
; IMMEDIATE

: ELSE              ( a1 -- a2 | a1: IF cell a2: ELSE cell )
    COMPILE (fbr)
    1 ALLOT
    DUP H@ -^ SWAP  ( a-H a )
    C!
    H@ 1 -          ( push a. -1 for allot offset )
; IMMEDIATE

: CREATE
    (entry)          ( empty header with name )
    ROUTINE C [LITN] ( push cellWord addr )
    ,                ( write it )
;
: VARIABLE CREATE 2 ALLOT ;
: CONSTANT CREATE H@ ! DOES> @ ;
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
    COMPILE I' COMPILE = COMPILE SKIP? COMPILE (bbr)
    H@ -^ C,
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
    ROUTINE Y [LITN] ,
    SYSVNXT @ ,
    2 SYSVNXT +!
;
