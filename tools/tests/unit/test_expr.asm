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


sFOO:		.db "FOO", 0
sBAR:		.db "BAR", 0

test:
	ld	sp, 0xffff

	; before testing begins, let's set up FOO and BAR symbols
	call	symInit
	ld	hl, sFOO
	ld	de, 0x4000
	call	symRegisterGlobal
	jp	nz, fail
	ld	hl, sBAR
	ld	de, 0x20
	call	symRegisterGlobal
	jp	nz, fail

	call	testParseExpr
	call	testSPOnFail

	; success
	xor	a
	halt

testParseExpr:
	ld	hl, .alltests
	ld	ix, .test
	jp	testList

.test:
	push	hl \ pop iy
	inc	hl \ inc hl
	call	parseExpr
	call	assertZ
	ld	l, (iy)
	ld	h, (iy+1)
	jp	assertEQW

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

; There was this untested regression during the replacement of find-and-subst
; parseExpr to the recursive descent one. It was time consuming to find. Here
; it goes, here it stays.
.t10:
	.dw	'-'+1
	.db	"'-'+1", 0

.t11:
	.dw	0x4023
	.db	"0x4001+0x22", 0

.t12:
	.dw	0x4020
	.db	"FOO+BAR", 0

.t13:
	.dw	0x60
	.db	"BAR*3", 0

.t14:
	.dw	0x3ffd
	.db	"FOO-3", 0

.t15:
	.dw	0x4080
	.db	"FOO+BAR*4", 0

.alltests:
	.dw	.t1, .t2, .t3, .t4, .t5, .t6, .t7, .t8, .t9, .t10, .t11, .t12
	.dw	.t13, .t14, .t15, 0

; Ensure that stack is balanced on failure
testSPOnFail:
	ld	(testSP), sp
	ld	hl, .sFail
	call	parseExpr
	call	assertNZ
	call	assertSP
	jp	nexttest

.sFail:	.db "1+abc123", 0

