jp	test

.inc "core.asm"
.inc "lib/util.asm"
.inc "lib/parse.asm"

zasmGetPC:
	ret

testNum:	.db 1

test:
	ld	sp, 0xffff

	call	testParseHex
	call	testParseHexadecimal

	; success
	xor	a
	halt

testParseHex:
	ld	a, '8'
	call	parseHex
	jp	c, fail
	cp	8
	jp	nz, fail
	call	nexttest

	ld	a, 'e'
	call	parseHex
	jp	c, fail
	cp	0xe
	jp	nz, fail
	call	nexttest

	ld	a, 'x'
	call	parseHex
	jp	nc, fail
	call	nexttest
	ret

testParseHexadecimal:
	ld	hl, .s99
	call	parseHexadecimal
	jp	nz, fail
	ld	a, e
	cp	0x99
	jp	nz, fail
	call	nexttest

	ld	hl, .saB
	call	parseHexadecimal
	jp	nz, fail
	ld	a, e
	cp	0xab
	jp	nz, fail
	call	nexttest

	; The string "Foo" will not cause a failure. We will parse up to "o"
	; and then stop.
	ld	hl, .sFoo
	call	parseHexadecimal
	jp	nz, fail
	ld	a, e
	cp	0xf
	call	nexttest
	ret

.sFoo:		.db "Foo", 0
.saB:		.db "aB", 0
.s99:		.db "99", 0

nexttest:
	ld	a, (testNum)
	inc	a
	ld	(testNum), a
	ret

fail:
	ld	a, (testNum)
	halt

; used as RAM
sandbox:
