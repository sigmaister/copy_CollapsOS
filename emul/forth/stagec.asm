.equ	RAMSTART	0xe800
.equ	HERE_INITIAL	CODE_END	; override
.equ	LATEST		CODE_END	; override
.equ	STDIO_PORT	0x00

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

.equ	GETC	emulGetC
.equ	PUTC	emulPutC
