( requires core )

: (parsec)          ( a -- n f )
    ( apostrophe is ASCII 39 )
    DUP C@ 39 = NOT IF 0 EXIT THEN      ( -- a 0 )
    DUP 2 + C@ 39 = NOT IF 0 EXIT THEN  ( -- a 0 )
    ( surrounded by apos, good, return )
    1 + C@ 1       ( -- n 1 )
;

: (parse)           ( a -- n )
    (parsec) NOT SKIP? EXIT
    (parsed) NOT SKIP? EXIT
    ( nothing works )
    ABORT" unknown word! "
;

' (parse) (parse*) !
