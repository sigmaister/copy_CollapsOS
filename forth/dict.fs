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

( Get word's prev offset )
( a -- a )
: PREV
    3 - DUP @                   ( a o )
    -                           ( a-o )
;
