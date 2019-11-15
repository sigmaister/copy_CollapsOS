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

; *** Shell ***
.inc "lib/util.asm"
.inc "lib/parse.asm"
.inc "lib/args.asm"
.inc "lib/stdio.asm"
.equ	SHELL_RAMSTART	STDIO_RAMEND
.equ	SHELL_EXTRA_CMD_COUNT 0
.inc "shell/main.asm"

init:
	di
	; setup stack
	ld	hl, RAMEND
	ld	sp, hl

	call	aciaInit
	call	kbdInit
	call	shellInit
	jp	shellLoop

KBD_FETCHKC:
	in	a, (KBD_PORT)
	ret

