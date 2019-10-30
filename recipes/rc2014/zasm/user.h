.equ    USER_CODE       0x8700
.equ    USER_RAMSTART   USER_CODE+0x1900
.equ    FS_HANDLE_SIZE  6
.equ    BLOCKDEV_SIZE   8

; *** JUMP TABLE ***
.equ    strncmp        0x03
.equ    addDE          @+3
.equ    addHL          @+3
.equ    upcase         @+3
.equ    unsetZ         @+3
.equ    intoDE         @+3
.equ    intoHL         @+3
.equ    writeHLinDE    @+3
.equ    findchar       @+3
.equ    parseHex       @+3
.equ    parseHexPair   @+3
.equ    blkSel         @+3
.equ    blkSet         @+3
.equ    fsFindFN       @+3
.equ    fsOpen         @+3
.equ    fsGetB         @+3
.equ    cpHLDE         @+3
; now at 0x36

.equ    parseArgs      0x3b
.equ    printstr       @+3
.equ    _blkGetB       @+3
.equ    _blkPutB       @+3
.equ    _blkSeek       @+3
.equ    _blkTell       @+3
.equ    printHexPair   @+3
.equ    sdcGetB        @+3
.equ    sdcPutB        @+3
.equ    blkGetB        @+3
