( Z80 assembler )

: CODE
    ( same as CREATE, but with ROUTINE V )
    (entry)
    ROUTINE V [LITN] ,
;

( Splits word into msb/lsb, lsb being on TOS )
: SPLITB
    DUP 0x100 /
    SWAP 0xff AND
;

( To debug, change C, to .X )
: A, C, ;
7 CONSTANT A
0 CONSTANT B
1 CONSTANT C
2 CONSTANT D
3 CONSTANT E
4 CONSTANT H
5 CONSTANT L
6 CONSTANT (HL)
0 CONSTANT BC
1 CONSTANT DE
2 CONSTANT HL
3 CONSTANT AF
3 CONSTANT SP

( -- )
: OP1 CREATE C, DOES> C@ A, ;
0xc9 OP1 RET,
0x76 OP1 HALT,

( r -- )
: OP1r
    CREATE C,
    DOES>
    C@              ( r op )
    SWAP            ( op r )
    8 *             ( op r<<3 )
    OR A,
;
0x04 OP1r INCr,
0x46 OP1r LDr(HL),
0x70 OP1r LD(HL)r,

( qq -- also works for ss )
: OP1qq
    CREATE C,
    DOES>
    C@              ( qq op )
    SWAP            ( op qq )
    16 *            ( op qq<<4 )
    OR A,
;
0xc5 OP1qq PUSHqq,
0xc1 OP1qq POPqq,
0x03 OP1qq INCss,
0x09 OP1qq ADHLss,

( rd rr )
: OP1rr
    CREATE C,
    DOES>
    C@              ( rd rr op )
    ROT             ( rr op rd )
    8 *             ( rr op rd<<3 )
    OR OR A,
;
0x40 OP1rr LDrr,

( n -- )
: OP2n
    CREATE C,
    DOES>
    C@ A, A,
;
0xd3 OP2n OUTAn,
0xdb OP2n INAn,

( r n -- )
: OP2rn
    CREATE C,
    DOES>
    C@              ( r n op )
    ROT             ( n op r )
    8 *             ( n op r<<3 )
    OR A, A,
;
0x06 OP2rn LDrn,

( b r -- )
: OP2br
    CREATE C,
    DOES>
    0xcb A,
    C@              ( b r op )
    ROT             ( r op b )
    8 *             ( r op b<<3 )
    OR OR Z,
;
0xc0 OP2br SETbr,
0x80 OP2br RESbr,
0x40 OP2br BITbr,

( dd nn -- )
: OP3ddnn
    CREATE C,
    DOES>
    C@              ( dd nn op )
    ROT             ( nn op dd )
    16 *            ( nn op dd<<4 )
    OR A,
    SPLITB A, A,
;
0x01 OP2ddnn LDddnn,

( nn -- )
: OP3nn
    CREATE C,
    DOES>
    C@ A,
    SPLITB A, A,
;
0xcd OP3nn CALLnn,
0xc3 OP3nn JPnn,

( Specials )
: JRe, 0x18 A, 2 - A, ;
: JPNEXT, ROUTINE N [LITN] JPnn, ;
