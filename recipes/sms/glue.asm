; 8K of onboard RAM
.equ	RAMSTART	0xc000
; Memory register at the end of RAM. Must not overwrite
.equ	RAMEND		0xfdd0

	jp	init

.fill 0x66-$
	retn

.inc "err.h"
.inc "ascii.h"
.inc "core.asm"
.inc "str.asm"

.equ	PAD_RAMSTART	RAMSTART
.inc "sms/pad.asm"

.inc "sms/vdp.asm"
.equ	GRID_RAMSTART	PAD_RAMEND
.equ	GRID_COLS	VDP_COLS
.equ	GRID_ROWS	VDP_ROWS
.equ	GRID_SETCELL	vdpSetCell
.inc "grid.asm"

.equ	STDIO_RAMSTART	GRID_RAMEND
.equ	STDIO_GETC	padGetC
.equ	STDIO_PUTC	gridPutC
.inc "stdio.asm"

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
.equ	BAS_RAMSTART	BUF_RAMEND
.inc "basic/main.asm"

init:
	di
	im	1

	ld	sp, RAMEND

	call	gridInit
	call	padInit
	call	vdpInit
	call	basInit
	jp	basStart

FNT_DATA:
.bin "fnt/7x7.bin"

.fill 0x7ff0-$
.db "TMR SEGA", 0x00, 0x00, 0xfb, 0x68, 0x00, 0x00, 0x00, 0x4c
