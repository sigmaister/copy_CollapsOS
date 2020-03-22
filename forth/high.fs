( Higher level stuff that generally requires all core units )

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
