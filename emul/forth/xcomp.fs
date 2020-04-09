: CODE XCODE ;
: IMMEDIATE XIMM ;
: : [ ' X: , ] ;

CURRENT @ XCURRENT !
H@ ' _bend - 4 + XOFF !

( dummy entry for dict hook )
(xentry) _
H@ 256 /MOD 2 PC! 2 PC!

