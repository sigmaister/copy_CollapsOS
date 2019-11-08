jp	test

.inc "core.asm"
.inc "parse.asm"

zasmGetPC:
	ret

testNum:	.db 1

test:
	ld	hl, 0xffff
	ld	sp, hl

	call	testParseHex
	call	testParseHexPair
	call	testParseArgs

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

testParseHexPair:
	ld	hl, .s99
	call	parseHexPair
	jp	c, fail
	cp	0x99
	jp	nz, fail
	call	nexttest

	ld	hl, .saB
	call	parseHexPair
	jp	c, fail
	cp	0xab
	jp	nz, fail
	call	nexttest

	ld	hl, .sFoo
	call	parseHexPair
	jp	nc, fail
	call	nexttest
	ret

.sFoo:		.db "Foo", 0
.saB:		.db "aB", 0
.s99:		.db "99", 0


testParseArgs:
	ld	hl, .t1+6
	ld	de, .t1
	ld	iy, .t1+3
	call	.testargs

	ld	hl, .t2+6
	ld	de, .t2
	ld	iy, .t2+3
	call	.testargs

	ld	hl, .t3+6
	ld	de, .t3
	ld	iy, .t3+3
	call	.testargs
	ret

; HL and DE must be set, and IY must point to expected results in IX
.testargs:
	ld	ix, sandbox
	call	parseArgs
	jp	nz, fail
	ld	a, (ix)
	cp	(iy)
	jp	nz, fail
	ld	a, (ix+1)
	cp	(iy+1)
	jp	nz, fail
	ld	a, (ix+2)
	cp	(iy+2)
	jp	nz, fail
	jp	nexttest

; Test data format: 3 bytes specs, 3 bytes expected (IX), then the arg string.

; Empty args with empty specs
.t1:
	.db 0b0000, 0b0000, 0b0000
	.db 0, 0, 0
	.db 0

; One arg, one byte spec
.t2:
	.db 0b0001, 0b0000, 0b0000
	.db 0xe4, 0, 0
	.db "e4", 0

; 3 args, 3 bytes spec
.t3:
	.db 0b0001, 0b0001, 0b0001
	.db 0xe4, 0xab, 0x99
	.db "e4 ab 99", 0

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
