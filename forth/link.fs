( depends: cmp
  Relink a dictionary by applying offsets to all word
  references in words of the "compiled" type.

  A typical usage of this unit would be to, right after a
  bootstrap-from-icore-from-source operation, to copy the
  dictionary from '< H@ to CURRENT, and then call RLDICT on
  that new range, with "ol" set to ' H@.
)

( Skip atom, considering special atom types. )
( a -- a+n )
: ASKIP
    DUP @       ( a n )
    ( ?br or br or NUMBER )
    DUP <>{ 0x70 &= 0x58 |= 0x20 |= <>}
    IF DROP 4 + EXIT THEN
    ( regular word )
    0x22 = NOT IF 2 + EXIT THEN
    ( it's a lit, skip to null char )
    ( a )
    1 + ( we skip by 2, but the loop below is pre-inc... )
    BEGIN 1 + DUP C@ NOT UNTIL
    ( a+1 )
;

( Get word header length from wordref. That is, name length
  + 3. a is a wordref )
( a -- n )
: WHLEN
    1 - C@      ( name len field )
    0x7f AND    ( remove IMMEDIATE flag )
    3 +         ( fixed header len )
;

( Get word addr, starting at name's address )
: '< ' DUP WHLEN - ;

( Relink atom at a, applying offset o with limit ol.
  Returns a, appropriately skipped.
)
( a o ol -- a+n )
: RLATOM
    ROT             ( o ol a )
    DUP @           ( o ol a n )
    ROT             ( o a n ol )
    < IF ( under limit, do nothing )
        SWAP DROP    ( a )
    ELSE
        ( o a )
        SWAP OVER @ ( a o n )
        -^          ( a n-o )
        OVER !      ( a )
    THEN
    ASKIP
;

( Relink a word with specified offset. If it's not of the type
  "compiled word", ignore. If it is, advance in word until a2
  is met, and for each word that is above ol, reduce that
  reference by o.
  Arguments: a1: wordref a2: word end addr o: offset to apply
             ol: offset limit. don't apply on refs under it.
)
( ol o a1 a2 -- )
: RLWORD
    SWAP DUP @              ( ol o a2 a1 n )
    ( 0e == compiledWord )
    0x0e = NOT IF
        ( unwind all args )
        2DROP 2DROP
        EXIT
    THEN
    ( we have a compiled word, proceed )
    ( ol o a2 a1 )
    2 +                         ( ol o a2 a1+2 )
    BEGIN                       ( ol o a2 a1 )
        2OVER                   ( ol o a2 a1 ol o )
        SWAP                    ( ol o a2 a1 o ol )
        RLATOM                  ( ol o a2 a+n )
        2DUP =                  ( ol o a2 a+n f )
        IF
            ( unwind )
            2DROP 2DROP
            EXIT
        THEN
    AGAIN
;

( Get word's prev offset )
( a -- a )
: PREV
    3 - DUP @                   ( a o )
    -                           ( a-o )
;

( Copy dict from target wordref, including header, up to HERE.
  We're going to compact the space between that word and its
  prev word. To do this, we're copying this whole memory area
  in HERE and then iterate through that copied area and call
  RLWORD on each word. That results in a dict that can be
  concatenated to target's prev entry in a more compact way.

  This copy of data doesn't allocate anything, so H@ doesn't
  move. Moreover, we reserve 4 bytes at H@ to write our target
  and offset because otherwise, things get too complicated
  with the PSP.

  This word prints the top copied address, so when comes the
  time to concat boot binary with this relinked dict, you
  can use H@+4 to printed addr.
)
( target -- )
: COMPACT
    ( First of all, let's get our offset. It's easy, it's
      target's prev field, which is already an offset, minus
      its name length. We expect, in COMPACT, that a target's
      prev word is a "hook word", that is, an empty word. )
    ( H@ == target )
    DUP H@ !
    DUP 1 - C@ 0x7f AND         ( t namelen )
    SWAP 3 - @                  ( namelen po )
    -^                          ( o )
    ( H@+2 == offset )
    H@ 2 + !                    ( )
    ( We have our offset, now let's copy our memory chunk )
    H@ @ DUP WHLEN -            ( src )
    DUP H@ -^                   ( src u )
    DUP ROT SWAP                ( u src u )
    H@ 4 +                      ( u src u dst )
    SWAP                        ( u src dst u )
    MOVE                        ( u )
    ( Now, let's iterate that dict down )
    ( wr == wordref we == word end )
    ( To get our wr and we, we use H@ and CURRENT, which we
      offset by u+4. +4 before, remember, we're using 4 bytes
      as variable space. )
    4 +                         ( u+4 )
    DUP H@ +                    ( u we )
    DUP .X LF
    SWAP CURRENT @ +            ( we wr )
    BEGIN                       ( we wr )
        DUP ROT                 ( wr wr we )
        ( call RLWORD. we need a sig: ol o wr we )
        H@ @                    ( wr wr we ol )
        H@ 2 + @                ( wr wr we ol o )
        2SWAP                   ( wr ol o wr we )
        RLWORD                  ( wr )
        ( wr becomes wr's prev and we is wr-header )
        DUP                     ( wr wr )
        PREV                    ( oldwr newwr )
        SWAP                    ( wr oldwr )
        DUP WHLEN -             ( wr we )
        SWAP                    ( we wr )
        ( Are we finished? We're finished if wr-4 <= H@ )
        DUP 4 - H@ <=
    UNTIL
;
