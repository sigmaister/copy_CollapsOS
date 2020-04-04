: INIT
    ACIA$
    (c<$)
    ." Collapse OS" LF
    ( 0c == CINPTR )
    ['] (c<) 0x0c RAM+ !
;
INIT

