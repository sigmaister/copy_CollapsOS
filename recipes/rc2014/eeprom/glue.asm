; classic RC2014 setup (8K ROM + 32K RAM) and a stock Serial I/O module
; The RAM module is selected on A15, so it has the range 0x8000-0xffff
.equ	RAMSTART	0x8000
.equ	RAMEND		0xffff
.equ	ACIA_CTL	0x80	; Control and status. RS off.
.equ	ACIA_IO		0x81	; Transmit. RS on.

jp	init

; interrupt hook
.fill	0x38-$
jp	aciaInt

.inc "err.h"
.inc "ascii.h"
.inc "blkdev.h"
.inc "core.asm"
.inc "str.asm"
.equ	ACIA_RAMSTART	RAMSTART
.inc "acia.asm"

.equ	MMAP_START	0xd000
.inc "mmap.asm"

.equ	BLOCKDEV_RAMSTART	ACIA_RAMEND
.equ	BLOCKDEV_COUNT		1
.inc "blockdev.asm"
; List of devices
.dw	mmapGetB, mmapPutB

.equ	STDIO_RAMSTART	BLOCKDEV_RAMEND
.equ	STDIO_GETC	aciaGetC
.equ	STDIO_PUTC	aciaPutC
.inc "stdio.asm"

.inc "lib/args.asm"
.equ	AT28W_RAMSTART	STDIO_RAMEND
.inc "at28w/main.asm"

; *** BASIC ***

; RAM space used in different routines for short term processing.
.equ	SCRATCHPAD_SIZE	STDIO_BUFSIZE
.equ	SCRATCHPAD	AT28W_RAMEND
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
.equ	BAS_RAMSTART	BUF_RAMEND
.inc "basic/main.asm"

init:
	di
	; setup stack
	ld	sp, RAMEND
	im 1

	call	aciaInit
	xor	a
	ld	de, BLOCKDEV_SEL
	call	blkSel

	call	basInit
	ld	hl, basFindCmdExtra
	ld	(BAS_FINDHOOK), hl
	ei
	jp	basStart

basFindCmdExtra:
	ld	hl, basBLKCmds
	call	basFindCmd
	ret	z
	ld	hl, .mycmds
	jp	basFindCmd
.mycmds:
	.db "at28w", 0
	.dw at28wMain
	.db 0xff
