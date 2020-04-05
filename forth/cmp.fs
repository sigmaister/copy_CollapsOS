( Words useful for complex comparison operations )

( n1 -- n1 true )
: <>{ 1 ;

( n1 f -- f )
: <>} SWAP DROP ;

( n1 f n2 -- n1 cmp )
: |CMP
    SWAP IF DROP 1 EXIT THEN ( n1 true )
    OVER SWAP                ( n1 n1 n2 )
    CMP
;

: &CMP
    SWAP NOT IF DROP 0 EXIT THEN ( n1 false )
    OVER SWAP                    ( n1 n1 n2 )
    CMP
;

( All words below have this signature:
  n1 f n2 -- n1 f )
: |= |CMP NOT ;
: &= &CMP NOT ;
: |< |CMP -1 = ;
: &< &CMP -1 = ;
: |> |CMP 1 = ;
: &> &CMP 1 = ;

