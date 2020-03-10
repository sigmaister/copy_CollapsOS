.inc "ascii.h"
.equ	RAMSTART	0x2000
.equ	STDIO_PORT	0x00

	jp	init

.inc "core.asm"
.inc "str.asm"

.equ	STDIO_RAMSTART	RAMSTART
.equ	STDIO_GETC	emulGetC
.equ	STDIO_PUTC	emulPutC
.inc "stdio.asm"

.inc "lib/util.asm"
.inc "lib/parse.asm"
.inc "lib/ari.asm"
.inc "lib/fmt.asm"
.equ FORTH_RAMSTART STDIO_RAMEND
.inc "forth/main.asm"
.inc "forth/util.asm"
.inc "forth/stack.asm"
.inc "forth/dict.asm"

init:
	di
	; setup stack
	ld	sp, 0xffff
	call	forthMain
	halt

emulGetC:
	; Blocks until a char is returned
	in	a, (STDIO_PORT)
	cp	a		; ensure Z
	ret

emulPutC:
	out	(STDIO_PORT), a
	ret
