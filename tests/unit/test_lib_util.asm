jp	test

.inc "ascii.h"
.inc "core.asm"
.equ	STDIO_RAMSTART	RAMSTART
.inc "stdio.asm"
.inc "common.asm"
.inc "lib/ari.asm"
.inc "lib/fmt.asm"
.inc "lib/util.asm"

test:
	ld	sp, 0xffff

	call	testRdWS

	; success
	xor	a
	halt

testRdWS:
	ld	hl, .allGood
	ld	ix, .testGood
	call	testList
	ld	hl, .allBad
	ld	ix, .testBad
	jp	testList

.testGood:
	call	rdWS
	jp	assertZ

.testBad:
	call	rdWS
	jp	assertNZ

; Strings ending with a non-WS, and thus yielding Z
.g1:
	.db	" X", 0
.g2:
	.db	"X", 0

.allGood:
	.dw	.g1, .g2, 0

; Strings ending with a WS, and thus yielding NZ
.b1:
	.db	0
.b2:
	.db	" ", 0

.allBad:
	.dw	.b1, .b2, 0

RAMSTART:
