.org    0x4800          ; in sync with USER_CODE in glue.asm
.equ    USER_RAMSTART   0x6000
.equ    FS_HANDLE_SIZE  8
.equ    BLOCKDEV_SIZE   8

; *** JUMP TABLE ***
.equ    strncmp        0x03
.equ    upcase         @+3
.equ    findchar       @+3
.equ    blkSel         @+3
.equ    blkSet         @+3
.equ    fsFindFN       @+3
.equ    fsOpen         @+3
.equ    fsGetB         @+3
.equ    _blkGetB       @+3
.equ    _blkPutB       @+3
.equ    _blkSeek       @+3
.equ    _blkTell       @+3
.equ    printstr       @+3
