( requires core, str )
( string being sent to parse routines are always null
  terminated )

: (parsec)          ( a -- n f )
    ( apostrophe is ASCII 39 )
    DUP C@ 39 = NOT IF 0 EXIT THEN      ( a 0 )
    DUP 2 + C@ 39 = NOT IF 0 EXIT THEN  ( a 0 )
    ( surrounded by apos, good, return )
    1 + C@ 1                            ( n 1 )
;

( returns negative value on error )
: hexdig            ( c -- n )
    ( '0' is ASCII 48 )
    48 -
    DUP 0 < IF EXIT THEN                ( bad )
    DUP 10 < IF EXIT THEN               ( good )
    ( 'a' is ASCII 97. 59 = 97 - 48 )
    49 -
    DUP 0 < IF EXIT THEN                ( bad )
    DUP 6 < IF 10 + EXIT THEN           ( good )
    ( bad )
    255 -
;

: (parseh)          ( a -- n f )
    ( '0': ASCII 0x30 'x': 0x78 0x7830: 30768 )
    DUP @ 30768 = NOT IF 0 EXIT THEN    ( a 0 )
    ( We have "0x" suffix )
    2 +
    ( validate slen )
    DUP SLEN                            ( a l )
    DUP 0 = IF DROP 0 EXIT THEN         ( a 0 )
    4 > IF DROP 0 EXIT THEN             ( a 0 )
    0 ( a r )
    BEGIN
    OVER C@
    DUP 0 = IF DROP SWAP DROP 1 EXIT THEN ( r, 1 )
    hexdig                              ( a r n )
    DUP 0 < IF DROP DROP 1 EXIT THEN    ( a 0 )
    SWAP 16 * +                         ( a r*16+n )
    SWAP 1 + SWAP                       ( a+1 r )
    AGAIN
;

: (parse)           ( a -- n )
    (parsec) NOT SKIP? EXIT
    (parseh) NOT SKIP? EXIT
    (parsed) NOT SKIP? EXIT
    ( nothing works )
    ABORT" unknown word! "
;

' (parse) (parse*) !
