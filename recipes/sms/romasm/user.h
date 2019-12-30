.equ    USER_CODE   0xc200
; Make ed fit in SMS's memory
.equ    ED_BUF_MAXLINES 0x100
.equ    ED_BUF_PADMAXLEN 0x800

; Make zasm fit in SMS's memory
.equ	ZASM_REG_MAXCNT		0x80
.equ	ZASM_LREG_MAXCNT	0x10
.equ	ZASM_REG_BUFSZ		0x800
.equ	ZASM_LREG_BUFSZ		0x100

; *** JUMP TABLE ***
.equ	strncmp			0x03
.equ	upcase			@+3
.equ	findchar		@+3
.equ	parseHex		@+3
.equ	blkSel			@+3
.equ	blkSet			@+3
.equ	fsFindFN		@+3
.equ	fsOpen			@+3
.equ	fsGetB			@+3
.equ	fsPutB			@+3
.equ	fsSetSize		@+3
.equ	printstr		@+3
.equ	_blkGetB		@+3
.equ	_blkPutB		@+3
.equ	_blkSeek		@+3
.equ	_blkTell		@+3
.equ	printcrlf		@+3
.equ	stdioPutC		@+3
.equ	stdioReadLine	@+3

