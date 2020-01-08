; 8K of onboard RAM
.equ	RAMSTART	0xc000
; Memory register at the end of RAM. Must not overwrite
.equ	RAMEND		0xddd0

	jp	init

.fill 0x66-$
	retn

.inc "err.h"
.inc "ascii.h"
.inc "core.asm"
.inc "str.asm"

.inc "sms/kbd.asm"
.equ	KBD_RAMSTART	RAMSTART
.equ	KBD_FETCHKC	smskbdFetchKCB
.inc "kbd.asm"

.equ	VDP_RAMSTART	KBD_RAMEND
.inc "sms/vdp.asm"

.equ	STDIO_RAMSTART	VDP_RAMEND
.equ	STDIO_GETC	kbdGetC
.equ	STDIO_PUTC	vdpPutC
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

	; Initialize the keyboard latch by "dummy reading" once. This ensures
	; that the adapter knows it can fill its '164.
	; Port B TH output, high
	ld	a, 0b11110111
	out	(0x3f), a
	nop
	; Port A/B reset
	ld	a, 0xff
	out	(0x3f), a

	call	kbdInit
	call	vdpInit
	call	basInit
	jp	basStart

FNT_DATA:
.bin "fnt/7x7.bin"

.fill 0x7ff0-$
.db "TMR SEGA", 0x00, 0x00, 0xfb, 0x68, 0x00, 0x00, 0x00, 0x4c

