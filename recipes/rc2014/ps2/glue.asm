.equ	RAMSTART	0x8000
.equ	RAMEND		0xffff
.equ	ACIA_CTL	0x80	; Control and status. RS off.
.equ	ACIA_IO		0x81	; Transmit. RS on.
.equ	KBD_PORT	0x08

jp	init

.inc "err.h"
.inc "ascii.h"
.inc "core.asm"
.inc "str.asm"
.equ	ACIA_RAMSTART	RAMSTART
.inc "acia.asm"

.equ	KBD_RAMSTART	ACIA_RAMEND
.inc "kbd.asm"

.equ	STDIO_RAMSTART	KBD_RAMEND
.equ	STDIO_GETC	kbdGetC
.equ	STDIO_PUTC	aciaPutC
.inc "stdio.asm"

; *** BASIC ***

; RAM space used in different routines for short term processing.
.equ	SCRATCHPAD_SIZE	0x20
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
	ld	sp, RAMEND
	im 1

	call	aciaInit
	call	kbdInit
	call	basInit
	ei
	jp	basStart

KBD_FETCHKC:
	in	a, (KBD_PORT)
	ret

