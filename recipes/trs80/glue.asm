; RAMSTART is a label at the end of the file
.equ	RAMEND		0xcfff

; Free memory in TRSDOS starts at 0x3000
.org	0x3000
	jp	init

.inc "err.h"
.inc "ascii.h"
.inc "core.asm"
.inc "str.asm"

.inc "trs80/kbd.asm"
.inc "trs80/vid.asm"

.equ	STDIO_RAMSTART	RAMSTART
.equ	STDIO_GETC	trs80GetC
.equ	STDIO_PUTC	trs80PutC
.inc "stdio.asm"

; The TRS-80 generates a double line feed if we give it both CR and LF.
.equ	printcrlf	printcr

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
	ld	sp, RAMEND
	call	basInit
	jp	basStart

printcr:
	push	af
	ld	a, CR
	call	STDIO_PUTC
	pop	af
	ret

RAMSTART:
