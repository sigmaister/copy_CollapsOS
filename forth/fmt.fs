( requires core, parse )

( TODO FORGET this word )
: PUSHDGTS
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
    PUSHDGTS
    BEGIN
    DUP '9' > IF DROP EXIT THEN ( stop indicator, we're done )
    EMIT
    AGAIN
;

: ? @ . ;

: PUSHDGTS
    999 SWAP        ( stop indicator )
    DUP 0 = IF '0' EXIT THEN    ( 0 is a special case )
    BEGIN
    DUP 0 = IF DROP EXIT THEN
    16 /MOD         ( r q )
    SWAP            ( r q )
    DUP 9 > IF 10 - 'a' +
    ELSE '0' + THEN ( q d )
    SWAP ( d q )
    AGAIN
;

: .X              ( n -- )
    ( For hex display, there are no negatives )
    PUSHDGTS
    BEGIN
    DUP 'f' > IF DROP EXIT THEN ( stop indicator, we're done )
    EMIT
    AGAIN
;
