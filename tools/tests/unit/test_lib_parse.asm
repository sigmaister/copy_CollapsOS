jp	test

.inc "ascii.h"
.inc "core.asm"
.equ	STDIO_RAMSTART	RAMSTART
.inc "stdio.asm"
.inc "common.asm"
.inc "lib/ari.asm"
.inc "lib/util.asm"
.inc "lib/fmt.asm"
.inc "lib/parse.asm"

test:
	ld	sp, 0xffff

	call	testParseHex
	call	testParseHexadecimal
	call	testParseDecimal
	call	testParseLiteral

	; success
	xor	a
	halt

testParseHex:
	ld	hl, .allGood
	ld	ix, .testGood
	call	testList
	ld	hl, .allBad
	ld	ix, .testBad
	jp	testList

.testGood:
	ld	a, (hl)
	call	parseHex
	call	assertNC
	inc	hl
	ld	b, (hl)
	jp	assertEQB

.testBad:
	ld	a, (hl)
	call	parseHex
	jp	assertC

.g1:
	.db	'8', 8
.g2:
	.db	'e', 0xe

.allGood:
	.dw	.g1, .g2, 0

.b1:
	.db	'x'

.allBad:
	.dw	.b1, 0

testParseHexadecimal:
	ld	hl, .allGood
	ld	ix, .testGood
	jp	testList

.testGood:
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	inc	hl
	call	parseHexadecimal
	call	assertZ
	ld	l, c
	ld	h, b
	jp	assertEQW

.g1:
	.dw	0x99
	.db	"99", 0
.g2:
	.dw	0xab
	.db	"aB", 0
; The string "Foo" will not cause a failure. We will parse up to "o" and then
; stop.
.g3:
	.dw	0xf
	.db	"Foo", 0

.allGood:
	.dw	.g1, .g2, .g3, 0

testParseDecimal:
	ld	hl, .allGood
	ld	ix, .testGood
	call	testList
	ld	hl, .allBad
	ld	ix, .testBad
	jp	testList

.testGood:
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	inc	hl
	call	parseDecimalC
	call	assertZ
	ld	l, c
	ld	h, b
	jp	assertEQW

.testBad:
	call	parseDecimalC
	jp	assertNZ

.g1:
	.dw	99
	.db	"99", 0
.g2:
	.dw	65535
	.db	"65535", 0
; Space is also accepted as a number "ender"
.g3:
	.dw	42
	.db	"42 x", 0
; Tab too
.g4:
	.dw	42
	.db	"42", 0x09, 'x', 0
; A simple "0" works too!
.g5:
	.dw	0
	.db	'0', 0

.allGood:
	.dw	.g1, .g2, .g3, .g4, .g5, 0

; null string is invalid
.b1:
	.db	0
; too big, 5 chars
.b2:
	.db	"65536", 0
.b3:
	.db	"99999", 0
.b4:
; too big, 6 chars with rightmost chars being within bound
	.db	"111111", 0

.allBad:
	.dw	.b1, .b2, .b3, .b4, 0

testParseLiteral:
	ld	hl, .allGood
	ld	ix, .testGood
	call	testList
	ld	hl, .allBad
	ld	ix, .testBad
	jp	testList

.testGood:
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	inc	hl
	call	parseLiteral
	call	assertZ
	ld	l, c
	ld	h, b
	jp	assertEQW

.testBad:
	call	parseLiteral
	jp	assertNZ

.g1:
	.dw	99
	.db	"99", 0
.g2:
	.dw	0x100
	.db	"0x100", 0
.g3:
	.dw	0b0101
	.db	"0b0101", 0
.g4:
	.dw	0b01010101
	.db	"0b01010101", 0

.allGood:
	.dw	.g1, .g2, .g3, .g4, 0

.b1:
	.db	"Foo", 0
.allBad:
	.dw	.b1, 0

RAMSTART:
