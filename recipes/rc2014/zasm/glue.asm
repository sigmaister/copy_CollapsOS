; classic RC2014 setup (8K ROM + 32K RAM) and a stock Serial I/O module
; The RAM module is selected on A15, so it has the range 0x8000-0xffff
.equ	RAMSTART	0x8000
; Kernel RAMEND last check: 0x9933
; We allocate at least 0x100 bytes for the stack, which is why we have this
; threshold.
.equ	RAMEND		0x9b00
.equ	USER_CODE	RAMEND  ; in sync with user.h
.equ	ACIA_CTL	0x80	; Control and status. RS off.
.equ	ACIA_IO		0x81	; Transmit. RS on.

	jp	init	; 3 bytes

; *** Jump Table ***
	jp	strncmp
	jp	upcase
	jp	findchar
	jp	blkSel
	jp	blkSet
	jp	fsFindFN
	jp	fsOpen
	jp	fsGetB
	jp	printstr
	jp	_blkGetB
	jp	_blkPutB
	jp	_blkSeek
	jp	_blkTell
	jp	sdcGetB
	jp	sdcPutB
	jp	blkGetB
	jp	stdioPutC

; interrupt hook
.fill	0x38-$
jp	aciaInt

.inc "err.h"
.inc "ascii.h"
.inc "blkdev.h"
.inc "fs.h"
.inc "core.asm"
.inc "str.asm"
.equ	ACIA_RAMSTART		RAMSTART
.inc "acia.asm"
.equ	BLOCKDEV_RAMSTART	ACIA_RAMEND
.equ	BLOCKDEV_COUNT		4
.inc "blockdev.asm"
; List of devices
.dw	sdcGetB, sdcPutB
.dw	blk1GetB, blk1PutB
.dw	blk2GetB, blk2PutB
.dw	mmapGetB, mmapPutB


.equ	MMAP_START	0xe000
.inc "mmap.asm"

.equ	STDIO_RAMSTART	BLOCKDEV_RAMEND
.equ	STDIO_GETC	aciaGetC
.equ	STDIO_PUTC	aciaPutC
.inc "stdio.asm"

.equ	FS_RAMSTART	STDIO_RAMEND
.equ	FS_HANDLE_COUNT	2
.inc "fs.asm"

; *** BASIC ***

; RAM space used in different routines for short term processing.
.equ	SCRATCHPAD_SIZE	STDIO_BUFSIZE
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

.out	SDC_RAMEND

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
	call	basFindCmd
	ret	z
	jp	basPgmHook

; *** blkdev 1: file handle 0 ***

blk1GetB:
	ld	ix, FS_HANDLES
	jp	fsGetB

blk1PutB:
	ld	ix, FS_HANDLES
	jp	fsPutB

; *** blkdev 2: file handle 1 ***

blk2GetB:
	ld	ix, FS_HANDLES+FS_HANDLE_SIZE
	jp	fsGetB

blk2PutB:
	ld	ix, FS_HANDLES+FS_HANDLE_SIZE
	jp	fsPutB
