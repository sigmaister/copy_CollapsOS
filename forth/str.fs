: SLEN      ( a -- n )
    DUP     ( astart aend )
    BEGIN
    DUP C@ 0 = IF -^ EXIT THEN
    1 +
    AGAIN
;

: BS 8 EMIT ;
: LF 10 EMIT ;
: CR 13 EMIT ;
: SPC 32 EMIT ;
