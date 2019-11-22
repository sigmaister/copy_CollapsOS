.equ	RAMSTART	0x4000
.equ	ZASM_REG_MAXCNT		0xff
.equ	ZASM_LREG_MAXCNT	0x40
.equ	ZASM_REG_BUFSZ		0x1000
.equ	ZASM_LREG_BUFSZ		0x200

; declare DIREC_LASTVAL manually so that we don't have to include directive.asm
.equ	DIREC_LASTVAL	RAMSTART

jp	test

.inc "core.asm"
.inc "str.asm"
.inc "lib/util.asm"
.inc "lib/ari.asm"
.inc "zasm/util.asm"
.inc "zasm/const.asm"
.inc "lib/parse.asm"
.inc "zasm/parse.asm"
.equ	SYM_RAMSTART	DIREC_LASTVAL+2
.inc "zasm/symbol.asm"
.equ	EXPR_PARSE	parseNumberOrSymbol
.inc "lib/expr.asm"

; Pretend that we aren't in first pass
zasmIsFirstPass:
	jp	unsetZ

zasmGetPC:
	ret

testNum:	.db 1

s1:		.db "2+2", 0
s2:		.db "0x4001+0x22", 0
s3:		.db "FOO+BAR", 0
s4:		.db "BAR*3", 0
s5:		.db "FOO-3", 0
s6:		.db "FOO+BAR*4", 0

sFOO:		.db "FOO", 0
sBAR:		.db "BAR", 0

test:
	ld	sp, 0xffff

	; Old-style tests, not touching them now.
	ld	hl, s1
	call	parseExpr
	jp	nz, fail
	push	ix \ pop hl
	ld	a, h
	or	a
	jp	nz, fail
	ld	a, l
	cp	4
	jp	nz, fail
	call	nexttest

	ld	hl, s2
	call	parseExpr
	jp	nz, fail
	push	ix \ pop hl
	ld	a, h
	cp	0x40
	jp	nz, fail
	ld	a, l
	cp	0x23
	jp	nz, fail
	call	nexttest

	; before the next test, let's set up FOO and BAR symbols
	call	symInit
	ld	hl, sFOO
	ld	de, 0x4000
	call	symRegisterGlobal
	jp	nz, fail
	ld	hl, sBAR
	ld	de, 0x20
	call	symRegisterGlobal
	jp	nz, fail

	ld	hl, s3
	call	parseExpr
	jp	nz, fail
	push	ix \ pop hl
	ld	a, h
	cp	0x40
	jp	nz, fail
	ld	a, l
	cp	0x20
	jp	nz, fail
	call	nexttest

	ld	hl, s4
	call	parseExpr
	jp	nz, fail
	push	ix \ pop hl
	ld	a, h
	or	a
	jp	nz, fail
	ld	a, l
	cp	0x60
	jp	nz, fail
	call	nexttest

	ld	hl, s5
	call	parseExpr
	jp	nz, fail
	push	ix \ pop hl
	ld	a, h
	cp	0x3f
	jp	nz, fail
	ld	a, l
	cp	0xfd
	jp	nz, fail
	call	nexttest

	ld	hl, s6
	call	parseExpr
	jp	nz, fail
	push	ix \ pop hl
	ld	a, h
	cp	0x40
	jp	nz, fail
	ld	a, l
	cp	0x80
	jp	nz, fail
	call	nexttest

	; New-style tests
	call	testParseExpr
	; success
	xor	a
	halt

testParseExpr:
	ld	iy, .t1
	call	.testEQ
	ld	iy, .t2
	call	.testEQ
	ld	iy, .t3
	call	.testEQ
	ld	iy, .t4
	call	.testEQ
	ld	iy, .t5
	call	.testEQ
	ret

.testEQ:
	push	iy \ pop hl
	inc	hl \ inc hl
	call	parseExpr
	jp	nz, fail
	push	ix \ pop de
	ld	a, e
	cp	(iy)
	jp	nz, fail
	ld	a, d
	cp	(iy+1)
	jp	nz, fail
	jp	nexttest

.t1:
	.dw	7
	.db	"42/6", 0
.t2:
	.dw	1
	.db	"7%3", 0
.t3:
	.dw	0x0907
	.db	"0x99f7&0x0f0f", 0
.t4:
	.dw	0x9fff
	.db	"0x99f7|0x0f0f", 0
.t5:
	.dw	0x96f8
	.db	"0x99f7^0x0f0f", 0

nexttest:
	ld	a, (testNum)
	inc	a
	ld	(testNum), a
	ret

fail:
	ld	a, (testNum)
	halt
