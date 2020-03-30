( Z80 assembler )

( Splits word into msb/lsb, lsb being on TOS )
: SPLITB
    256 /MOD SWAP
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

( As a general rule, IX and IY are equivalent to spitting an
  extra 0xdd / 0xfd and then spit the equivalent of HL )
: IX 0xdd A, HL ;
: IY 0xfd A, HL ;
: _ix+- 0xff AND 0xdd A, (HL) ;
: _iy+- 0xff AND 0xfd A, (HL) ;
: IX+ _ix+- ;
: IX- 0 -^ _ix+- ;
: IY+ _iy+- ;
: IY- 0 -^ _iy+- ;

: <<3 8 * ;
: <<4 16 * ;

( -- )
: OP1 CREATE C, DOES> C@ A, ;
0xeb OP1 EXDEHL,
0x76 OP1 HALT,
0x12 OP1 LD(DE)A,
0x1a OP1 LDA(DE),
0xc9 OP1 RET,
0x17 OP1 RLA,
0x07 OP1 RLCA,
0x1f OP1 RRA,
0x0f OP1 RRCA,
0x37 OP1 SCF,

( r -- )
: OP1r
    CREATE C,
    DOES>
    C@              ( r op )
    SWAP            ( op r )
    <<3             ( op r<<3 )
    OR A,
;
0x04 OP1r INCr,
0x05 OP1r DECr,

( r -- )
: OP1r0
    CREATE C,
    DOES>
    C@              ( r op )
    OR A,
;
0xa0 OP1r0 ANDr,
0xb0 OP1r0 ORr,
0xa8 OP1r0 XORr,
0xb8 OP1r0 CPr,

( qq -- also works for ss )
: OP1qq
    CREATE C,
    DOES>
    C@              ( qq op )
    SWAP            ( op qq )
    <<4             ( op qq<<4 )
    OR A,
;
0xc5 OP1qq PUSHqq,
0xc1 OP1qq POPqq,
0x03 OP1qq INCss,
0x0b OP1qq DECss,
0x09 OP1qq ADDHLss,

: _1rr
    C@              ( rd rr op )
    ROT             ( rr op rd )
    <<3             ( rr op rd<<3 )
    OR OR A,
;

( rd rr )
: OP1rr
    CREATE C,
    DOES>
    _1rr
;
0x40 OP1rr LDrr,

( ixy+- HL rd )
: LDIXYr,
    ( dd/fd has already been spit )
    LDrr,           ( ixy+- )
    A,
;

( rd ixy+- HL )
: LDrIXY,
    ROT             ( ixy+- HL rd )
    SWAP            ( ixy+- rd HL )
    LDIXYr,
;

( n -- )
: OP2n
    CREATE C,
    DOES>
    C@ A, A,
;
0xd3 OP2n OUTnA,
0xdb OP2n INAn,

( r n -- )
: OP2rn
    CREATE C,
    DOES>
    C@              ( r n op )
    ROT             ( n op r )
    <<3             ( n op r<<3 )
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
    <<3             ( r op b<<3 )
    OR OR A,
;
0xc0 OP2br SETbr,
0x80 OP2br RESbr,
0x40 OP2br BITbr,

( bitwise rotation ops have a similar sig )
( r -- )
: OProt
    CREATE C,
    DOES>
    0xcb A,
    C@              ( r op )
    OR A,
;
0x10 OProt RLr,
0x00 OProt RLCr,
0x18 OProt RRr,
0x08 OProt RRCr,
0x20 OProt SLAr,
0x38 OProt SRLr,

( cell contains both bytes. MSB is spit as-is, LSB is ORed with r )
( r -- )
: OP2r
    CREATE ,
    DOES>
    @ SPLITB SWAP   ( r lsb msb )
    A,              ( r lsb )
    SWAP <<3        ( lsb r<<3 )
    OR A,
;
0xed41 OP2r OUT(C)r,
0xed40 OP2r INr(C),

( ss -- )
: OP2ss
    CREATE C,
    DOES>
    0xed A,
    C@ SWAP         ( op ss )
    <<4             ( op ss<< 4 )
    OR A,
;
0x4a OP2ss ADCHLss,
0x42 OP2ss SBCHLss,

( dd nn -- )
: OP3ddnn
    CREATE C,
    DOES>
    C@              ( dd nn op )
    ROT             ( nn op dd )
    <<4             ( nn op dd<<4 )
    OR A,
    SPLITB A, A,
;
0x01 OP3ddnn LDddnn,

( nn -- )
: OP3nn
    CREATE C,
    DOES>
    C@ A,
    SPLITB A, A,
;
0xcd OP3nn CALLnn,
0xc3 OP3nn JPnn,
0x22 OP3nn LD(nn)HL,
0x2a OP3nn LDHL(nn),

: OPJR
    CREATE C,
    DOES>
    C@ A, 2 - A,
;
0x18 OPJR JRe,
0x38 OPJR JRCe,
0x30 OPJR JRNCe,
0x28 OPJR JRZe,
0x20 OPJR JRNZe,
0x10 OPJR DJNZe,

( Specials )

( dd nn -- )
: LDdd(nn),
    0xed A,
    SWAP <<4 0x4b OR A,
    SPLITB A, A,
;

( nn dd -- )
: LD(nn)dd,
    0xed A,
    <<4 0x43 OR A,
    SPLITB A, A,
;

( 26 == next )
: JPNEXT, 26 JPnn, ;

: CODE
    ( same as CREATE, but with native word )
    (entry)
    ( 23 == nativeWord )
    23 ,
;

: ;CODE JPNEXT, ;


( Routines )
( 29 == chkPS )
: chkPS, 29 CALLnn, ;
