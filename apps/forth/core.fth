: ? @ . ;
: +! SWAP OVER @ + SWAP ! ;
: ALLOT HERE +! ;
: VARIABLE CREATE 2 ALLOT ;
: CONSTANT CREATE HERE @ ! DOES> @ ;
: NOT IF 0 ELSE 1 THEN ;
: = CMP NOT ;
: < CMP 0 1 - = ;
: > CMP 1 = ;
