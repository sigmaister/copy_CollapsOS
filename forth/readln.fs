( requires core, parse, print )

( Managing variables in a core module is tricky. Sure, we
  have (sysv), but here we need to allocate a big buffer, and
  that cannot be done through (sysv). What we do is that we
  allocate that buffer at runtime and use (sysv) to point to
  it, a pointer that is set during the initialization
  routine. )

64 CONSTANT INBUFSZ
( points to INBUF )
(sysv) IN(
( points to INBUF's end )
(sysv) IN)
( current position in INBUF )
(sysv) IN>

( flush input buffer )
( set IN> to IN( and set IN> @ to null )
: (infl) 0 IN( @ DUP IN> ! ! ;

( Initializes the readln subsystem )
: (c<$)
    H@ IN( !
    INBUFSZ ALLOT
    H@ IN) !
    ( We need two extra bytes. 1 for the last typed 0x0a and
      one for the following NULL. )
    2 ALLOT
    (infl)
;

( handle backspace: go back one char in IN>, if possible, then
  emit SPC + BS )
: (inbs)
    ( already at IN( ? )
    IN> @ IN( @ = IF EXIT THEN
    IN> @ 1 - IN> !
    SPC BS
;

( read one char into input buffer and returns whether we
  should continue, that is, whether newline was not met. )
: (rdlnc)                   ( -- f )
    ( buffer overflow? same as if we typed a newline )
    IN> @ IN) @ = IF 0x0a ELSE KEY THEN     ( c )
    ( del? same as backspace )
    DUP 0x7f = IF DROP 0x8 THEN
    ( echo back )
    DUP EMIT                    ( c )
    ( bacspace? handle and exit )
    DUP 0x8 = IF (inbs) EXIT THEN
    ( write and advance )
    DUP     ( keep as result )  ( c c )
    ( Here, we take advantage of the fact that c's MSB is
      always zero and thus ! automatically null-terminates
      our string )
    IN> @ ! 1 IN> +!            ( c )
    ( if newline, replace with zero to indicate EOL )
    DUP 0xa = IF DROP 0 THEN
;

( Read one line in input buffer and make IN> point to it )
: (rdln)
    ( Should we prompt? if we're executing a word, FLAGS bit
      0, then we shouldn't. )
    FLAGS @ 0x1 AND NOT IF LF '>' EMIT SPC THEN
    (infl)
    BEGIN (rdlnc) NOT UNTIL
    IN( @ IN> !
;

( And finally, implement a replacement for the (c<) routine )
: (c<)
    IN> @ C@                    ( c )
    ( not EOL? good, inc and return )
    DUP IF 1 IN> +! EXIT THEN   ( c )
    ( EOL ? readline. we still return typed char though )
    (rdln)                      ( c )
;
