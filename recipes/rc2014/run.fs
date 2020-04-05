: INIT
    ACIA$
    (c<$)
    ." Collapse OS" CR LF
    ( 0c == CINPTR )
    ['] (c<) 0x0c RAM+ !
;
INIT

