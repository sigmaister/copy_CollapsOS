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
