.equ	RAMSTART	0x4000
.equ	ZASM_REG_MAXCNT		0xff
.equ	ZASM_LREG_MAXCNT	0x40
.equ	ZASM_REG_BUFSZ		0x1000
.equ	ZASM_LREG_BUFSZ		0x200

; declare DIREC_LASTVAL manually so that we don't have to include directive.asm
.equ	DIREC_LASTVAL	RAMSTART

jp	test

.inc "ascii.h"
.inc "core.asm"
.inc "str.asm"
.inc "lib/util.asm"
.inc "lib/ari.asm"
.inc "lib/fmt.asm"
.inc "zasm/util.asm"
.inc "zasm/const.asm"
.inc "lib/parse.asm"
.inc "zasm/parse.asm"
.equ	SYM_RAMSTART	DIREC_LASTVAL+2
.inc "zasm/symbol.asm"
.equ	EXPR_PARSE	parseNumberOrSymbol
.inc "lib/expr.asm"
.equ	STDIO_RAMSTART	SYM_RAMEND
.inc "stdio.asm"
.inc "common.asm"

; Pretend that we aren't in first pass
zasmIsFirstPass:
	jp	unsetZ

zasmGetPC:
	ret

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

	; New-style tests
	;call	testParseExpr

	; Old-style tests, not touching them now.
	ld	hl, s1
	call	parseExprDE
	call	assertZ
	ld	hl, 4
	call	assertEQW
	call	nexttest

	ld	hl, s2
	call	parseExprDE
	call	assertZ
	ld	hl, 0x4023
	call	assertEQW
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
	call	parseExprDE
	call	assertZ
	ld	hl, 0x4020
	call	assertEQW
	call	nexttest

	ld	hl, s4
	call	parseExprDE
	call	assertZ
	ld	hl, 0x60
	call	assertEQW
	call	nexttest

	ld	hl, s5
	call	parseExprDE
	call	assertZ
	ld	hl, 0x3ffd
	call	assertEQW
	call	nexttest

	ld	hl, s6
	call	parseExprDE
	call	assertZ
	ld	hl, 0x4080
	call	assertEQW
	call	nexttest

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
	ld	iy, .t6
	call	.testEQ
	ld	iy, .t7
	call	.testEQ
	ld	iy, .t8
	call	.testEQ
	ld	iy, .t9
	call	.testEQ
	ret

.testEQ:
	push	iy \ pop hl
	inc	hl \ inc hl
	call	parseExprDE
	call	assertZ
	ld	l, (iy)
	ld	h, (iy+1)
	call	assertEQW
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
.t6:
	.dw	0x133e
	.db	"0x99f7}3", 0
.t7:
	.dw	0xcfb8
	.db	"0x99f7{3", 0
.t8:
	.dw	0xffff
	.db	"-1", 0
.t9:
	.dw	10
	.db	"2*3+4", 0
