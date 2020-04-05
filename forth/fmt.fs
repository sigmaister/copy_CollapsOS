( requires core, parse )

: _
    999 SWAP        ( stop indicator )
    DUP 0 = IF '0' EXIT THEN    ( 0 is a special case )
    BEGIN
    DUP 0 = IF DROP EXIT THEN
    10 /MOD         ( r q )
    SWAP '0' + SWAP ( d q )
    AGAIN
;

: .               ( n -- )
    ( handle negative )
    ( that "0 1 -" thing is because we don't parse negative
      number correctly yet. )
    DUP 0 < IF '-' EMIT 0 1 - * THEN
    _
    BEGIN
    DUP '9' > IF DROP EXIT THEN ( stop indicator, we're done )
    EMIT
    AGAIN
;

: ? @ . ;

: _
    DUP 9 > IF 10 - 'a' +
    ELSE '0' + THEN
;

( For hex display, there are no negatives )

: .x
    256 MOD     ( ensure < 0x100 )
    16 /MOD     ( l h )
    _ EMIT ( l )
    _ EMIT
;

: .X
    256 /MOD    ( l h )
    .x .x
;
