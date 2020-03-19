: SLEN      ( a -- n )
    DUP     ( astart aend )
    BEGIN
    DUP C@ 0 = IF -^ EXIT THEN
    1 +
    AGAIN
;

: LF 10 EMIT ;
: SPC 32 EMIT ;
