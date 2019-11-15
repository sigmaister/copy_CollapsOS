.org    0x8700

; *** JUMP TABLE ***
.equ    strncmp        0x03
.equ    upcase         @+3
.equ    findchar       @+3
.equ    parseHex       @+3
.equ    parseHexPair   @+3
.equ    blkSel         @+3
.equ    blkSet         @+3
.equ    fsFindFN       @+3
.equ    fsOpen         @+3
.equ    fsGetB         @+3
.equ    parseArgs      @+3
.equ    printstr       @+3
.equ    _blkGetB       @+3
.equ    _blkPutB       @+3
.equ    _blkSeek       @+3
.equ    _blkTell       @+3
.equ    printHexPair   @+3
; now at 0x36

.equ    sdcGetB        0x3b
.equ    sdcPutB        @+3
.equ    blkGetB        @+3
