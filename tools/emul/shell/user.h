.org    0x4200              ; in sync with USERCODE in shell/shell_.asm
.equ    FS_HANDLE_SIZE  8
.equ    BLOCKDEV_SIZE   8

; *** JUMP TABLE ***
.equ	strncmp			0x03
.equ	upcase			@+3
.equ	findchar		@+3
.equ	parseHex		@+3
.equ	parseHexPair	@+3
.equ	blkSel			@+3
.equ	blkSet			@+3
.equ	fsFindFN		@+3
.equ	fsOpen			@+3
.equ	fsGetB			@+3
.equ	fsPutB			@+3
.equ	fsSetSize		@+3
.equ	parseArgs		@+3
.equ	printstr		@+3
.equ	_blkGetB		@+3
.equ	_blkPutB		@+3
.equ	_blkSeek		@+3
.equ	_blkTell		@+3
.equ	printcrlf		@+3
.equ	stdioPutC		@+3
.equ	stdioReadLine	@+3
