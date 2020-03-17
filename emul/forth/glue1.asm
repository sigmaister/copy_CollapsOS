; Warning: The offsets of native dict entries must be exactly the same between
;          glue0.asm and glue1.asm
.equ	LATEST		CODE_END	; override
.inc "ascii.h"
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

.out $		; should be the same as in glue0, minus 2
; stage0 spits, at the beginning of the binary, the address of the latest word
; Therefore, we can set the LATEST label to here and we should be good.
CODE_END:
.bin "core.bin"
RAMSTART:
