; RAMSTART is a label at the end of the file
.equ	RAMEND		0xcfff

; Free memory in TRSDOS starts at 0x3000
.org	0x3000
	jp	init

.inc "err.h"
.inc "blkdev.h"
.inc "ascii.h"
.inc "core.asm"
.inc "str.asm"

.inc "trs80/kbd.asm"
.inc "trs80/vid.asm"
.equ	FLOPPY_RAMSTART	RAMSTART
.inc "trs80/floppy.asm"

.equ	BLOCKDEV_RAMSTART	FLOPPY_RAMEND
.equ	BLOCKDEV_COUNT		1
.inc "blockdev.asm"
; List of devices
.dw	floppyGetB, floppyPutB

.equ	STDIO_RAMSTART	BLOCKDEV_RAMEND
.equ	STDIO_GETC	trs80GetC
.equ	STDIO_PUTC	trs80PutC
.inc "stdio.asm"

; The TRS-80 generates a double line feed if we give it both CR and LF.
.equ	printcrlf	printcr

; *** BASIC ***

; RAM space used in different routines for short term processing.
.equ	SCRATCHPAD_SIZE	STDIO_BUFSIZE
.equ	SCRATCHPAD	STDIO_RAMEND
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
	ld	sp, RAMEND
	call	floppyInit
	call	basInit
	ld	hl, basFindCmdExtra
	ld	(BAS_FINDHOOK), hl

	xor	a
	ld	de, BLOCKDEV_SEL
	call	blkSel

	jp	basStart

printcr:
	push	af
	ld	a, CR
	call	STDIO_PUTC
	pop	af
	ret

basFindCmdExtra:
	ld	hl, basBLKCmds
	jp	basFindCmd

RAMSTART:
