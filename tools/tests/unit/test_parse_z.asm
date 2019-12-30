jp	test

.inc "core.asm"
.inc "str.asm"
.inc "lib/util.asm"
.inc "zasm/util.asm"
.inc "lib/parse.asm"

; mocks. aren't used in tests
zasmGetPC:
zasmIsFirstPass:
symSelect:
symFindVal:
	jp	fail

testNum:	.db 1

s99:		.db "99", 0
s0x99:		.db "0x99", 0
s0x100:		.db "0x100", 0
s0b0101:	.db "0b0101", 0
s0b01010101:	.db "0b01010101", 0
sFoo:		.db "Foo", 0

test:
	ld	sp, 0xffff

	call	testLiteral
	call	testDecimal

	; success
	xor	a
	halt

testLiteral:
	ld	hl, s99
	call	parseLiteral
	jp	nz, fail
	ld	a, d
	or	a
	jp	nz, fail
	ld	a, e
	cp	99
	jp	nz, fail
	call	nexttest

	ld	hl, s0x100
	call	parseLiteral
	jp	nz, fail
	ld	a, d
	cp	1
	jp	nz, fail
	ld	a, e
	or	a
	jp	nz, fail
	call	nexttest

	ld	hl, sFoo
	call	parseLiteral
	jp	z, fail
	call	nexttest

	ld	hl, s0b0101
	call	parseLiteral
	jp	nz, fail
	ld	a, d
	or	a
	jp	nz, fail
	ld	a, e
	cp	0b0101
	jp	nz, fail
	call	nexttest

	ld	hl, s0b01010101
	call	parseLiteral
	jp	nz, fail
	ld	a, d
	or	a
	jp	nz, fail
	ld	a, e
	cp	0b01010101
	jp	nz, fail
	call	nexttest

.equ	FOO		0x42
.equ	BAR		@+1
	ld	a, BAR
	cp	0x43
	jp	nz, fail
	call	nexttest
	ret

testDecimal:

; test valid cases. We loop through tblDecimalValid for our cases
	ld	b, 5
	ld	hl, .valid

.loop1:
	push	hl	; --> lvl 1
	; put expected number in IX
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	inc	hl
	push	de \ pop ix
	call	parseDecimalC	; --> DE
	jp	nz, fail
	push	ix \ pop hl	; push expected number in HL
	ld	a, h
	cp	d
	jp	nz, fail
	ld	a, l
	cp	e
	jp	nz, fail
	pop	hl	; <-- lvl 1
	ld	de, 8	; row size
	add	hl, de
	djnz	.loop1
	call	nexttest

; test invalid cases. We loop through tblDecimalInvalid for our cases
	ld	b, 4
	ld	hl, .invalid

.loop2:
	push	hl
	call	parseDecimalC
	pop	hl
	jp	z, fail
	ld	de, 7	; row size
	add	hl, de
	djnz	.loop2
	call	nexttest
	ret

; 2b int, 6b str, null-padded
.valid:
	.dw	99
	.db	"99", 0, 0, 0, 0
	.dw	65535
	.db	"65535", 0
	; Space is also accepted as a number "ender"
	.dw	42
	.db	"42 x", 0, 0
	; Tab too
	.dw	42
	.db	"42", 0x09, 'x', 0, 0
	; A simple "0" works too!
	.dw	0
	.db	'0', 0, 0, 0, 0, 0


; 7b strings, null-padded
.invalid:
	; null string is invalid
	.db	0, 0, 0, 0, 0, 0, 0
	; too big, 5 chars
	.db	"65536", 0, 0
	.db	"99999", 0, 0
	; too big, 6 chars with rightmost chars being within bound
	.db	"111111", 0


nexttest:
	ld	a, (testNum)
	inc	a
	ld	(testNum), a
	ret

fail:
	ld	a, (testNum)
	halt


