; classic RC2014 setup (8K ROM + 32K RAM) and a stock Serial I/O module
; The RAM module is selected on A15, so it has the range 0x8000-0xffff
.equ	RAMSTART	0x8000
.equ	RAMEND		0xffff
.equ	ACIA_CTL	0x80	; Control and status. RS off.
.equ	ACIA_IO		0x81	; Transmit. RS on.
.equ	USER_CODE	0xa000

jp	init	; 3 bytes

; *** Jump Table ***
jp	printstr
jp	sdcWaitResp
jp	sdcCmd
jp	sdcCmdR1
jp	sdcCmdR7
jp	sdcSendRecv

; interrupt hook
.fill	0x38-$
jp	aciaInt

.inc "err.h"
.inc "ascii.h"
.inc "blkdev.h"
.inc "fs.h"
.inc "core.asm"
.inc "str.asm"
.equ	ACIA_RAMSTART	RAMSTART
.inc "acia.asm"
.equ	BLOCKDEV_RAMSTART	ACIA_RAMEND
.equ	BLOCKDEV_COUNT		2
.inc "blockdev.asm"
; List of devices
.dw	sdcGetB, sdcPutB
.dw	blk2GetB, blk2PutB


.equ	STDIO_RAMSTART	BLOCKDEV_RAMEND
.equ	STDIO_GETC	aciaGetC
.equ	STDIO_PUTC	aciaPutC
.inc "stdio.asm"

.equ	FS_RAMSTART	STDIO_RAMEND
.equ	FS_HANDLE_COUNT	1
.inc "fs.asm"

; *** BASIC ***

; RAM space used in different routines for short term processing.
.equ	SCRATCHPAD_SIZE	0x20
.equ	SCRATCHPAD	FS_RAMEND
.inc "lib/util.asm"
.inc "lib/ari.asm"
.inc "lib/parse.asm"
.inc "lib/fmt.asm"
.equ	EXPR_PARSE	parseLiteralOrVar
.inc "lib/expr.asm"
.inc "basic/util.asm"
.inc "basic/parse.asm"
.inc "basic/tok.asm"
.equ	VAR_RAMSTART	SCRATCHPAD+SCRATCHPAD_SIZE
.inc "basic/var.asm"
.equ	BUF_RAMSTART	VAR_RAMEND
.inc "basic/buf.asm"
.inc "basic/blk.asm"
.inc "basic/sdc.asm"
.equ	BFS_RAMSTART	BUF_RAMEND
.inc "basic/fs.asm"
.equ	BAS_RAMSTART	BFS_RAMEND
.inc "basic/main.asm"

.equ	SDC_RAMSTART	BAS_RAMEND
.equ	SDC_PORT_CSHIGH	6
.equ	SDC_PORT_CSLOW	5
.equ	SDC_PORT_SPI	4
.inc "sdc.asm"

init:
	di
	ld	sp, RAMEND
	im	1
	call	aciaInit
	call	fsInit
	call	basInit
	ld	hl, basFindCmdExtra
	ld	(BAS_FINDHOOK), hl

	xor	a
	ld	de, BLOCKDEV_SEL
	call	blkSel

	ei
	jp	basStart

basFindCmdExtra:
	ld	hl, basFSCmds
	call	basFindCmd
	ret	z
	ld	hl, basBLKCmds
	call	basFindCmd
	ret	z
	ld	hl, basSDCCmds
	jp	basFindCmd

; *** blkdev 2: file handle 0 ***

blk2GetB:
	ld	ix, FS_HANDLES
	jp	fsGetB

blk2PutB:
	ld	ix, FS_HANDLES
	jp	fsPutB
