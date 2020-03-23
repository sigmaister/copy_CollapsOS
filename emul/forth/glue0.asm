.equ	RAMSTART	0xe800
.equ	HERE_INITIAL	CODE_END	; override
.equ	STDIO_PORT	0x00

	jp	init

.equ	GETC	emulGetC
.equ	PUTC	emulPutC
.inc "forth.asm"

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

CODE_END:
.out LATEST
.out $		; should be the same as in glue1
