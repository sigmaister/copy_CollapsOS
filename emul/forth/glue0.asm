; RAM disposition
;
; Because this glue code also serves stage0 which needs HERE to start right
; after the code, we have a peculiar RAM setup here: it lives at the very end
; of the address space, just under RS_ADDR at 0xf000
; Warning: The offsets of native dict entries must be exactly the same between
;          glue0.asm and glue1.asm
.equ	RAMSTART	0xe800
.equ	HERE		0xe700		; override, in sync with stage1.c
.equ	CURRENT		0xe702		; override, in sync with stage1.c
.equ	HERE_INITIAL	CODE_END	; override

.inc "ascii.h"
.equ	STDIO_PORT	0x00

	jp	init


.equ	STDIO_RAMSTART	RAMSTART
.equ	STDIO_GETC	emulGetC
.equ	STDIO_PUTC	emulPutC
.inc "stdio.asm"

.equ FORTH_RAMSTART STDIO_RAMEND
.inc "main.asm"
.inc "util.asm"
.inc "stack.asm"
.inc "dict.asm"


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

.dw	0		; placeholder used in glue1.
CODE_END:
.out $		; should be the same as in glue1
