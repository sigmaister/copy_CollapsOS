: _
    ['] EXIT ,
    R> DROP     ( exit : )
    XCOFF
; IMMEDIATE
';' CURRENT @ 4 - C!

: (find) (xfind) ;
: ['] X['] ; IMMEDIATE
: COMPILE XCOMPILE ; IMMEDIATE
: CODE XCODE ;
: IMMEDIATE XIMM ;
: : [ ' X: , ] ;

CURRENT @ XCURRENT !

H@ 256 /MOD 2 PC! 2 PC!
H@ XOFF !
