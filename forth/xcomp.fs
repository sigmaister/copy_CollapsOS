( Cross-compilation tools

  This allows for a second dictionary to be built using the
  full power of our main one. It works by replacing saving
  CURRENT into ALTD and replacing (find) with a word that
  tries, when failing a first time, to find the word in ALTD.

  This way, what you can do is to start writing a dictionary
  root (an entry with a prev field to zero), refer subsequent
  words to it, find words into it on the fly *and* still
  access your full powered words from ALTD.

  This is used to bootstrap a new Forth impl.
)


VARIABLE ALTD
0 ALTD !

: _oldf (find) ;

: (find)
    ( Do we have an ALTD? )
    ALTD @ NOT IF ( no, just call old ) _oldf EXIT THEN
    ( We have an ALTD )
    DUP     ( w w )
    _oldf   ( w a f )
    IF
        ( found on the first try )
        SWAP DROP ( drop word backup )
        1         ( success )
    ELSE
        DROP      ( w )
        ( not found, try ALTD )
        ALTD @ CURRENT @ ALTD ! CURRENT !
        BYE
        _oldf
        ( restore )
        ALTD @ CURRENT @ ALTD ! CURRENT !
    THEN
;

( 0e == FINDPTR, set new find )
( CURRENT @ 0x0e RAM+ ! )

( Start a xcomp session )
: XCOMP CURRENT @ ALTD ! ;
