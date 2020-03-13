: H HERE @ ;
: -^ SWAP - ;
: ? @ . ;
: +! SWAP OVER @ + SWAP ! ;
: ALLOT HERE +! ;
: VARIABLE CREATE 2 ALLOT ;
: CONSTANT CREATE H ! DOES> @ ;
: , H ! 2 ALLOT ;
: C, H C! 1 ALLOT ;
: IF ['] (fbr?) , H 0 C, ; IMMEDIATE
: THEN DUP H -^ SWAP C! ; IMMEDIATE
: ELSE ['] (fbr) , 0 C, DUP H -^ SWAP C! H 1 - ; IMMEDIATE
: NOT IF 0 ELSE 1 THEN ;
: = CMP NOT ;
: < CMP 0 1 - = ;
: > CMP 1 = ;
