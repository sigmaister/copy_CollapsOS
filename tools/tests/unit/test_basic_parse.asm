jp	test

.inc "core.asm"
.inc "str.asm"
.inc "lib/util.asm"
.inc "lib/parse.asm"
.equ	EXPR_PARSE	parseLiteral
.inc "lib/expr.asm"
.inc "basic/parse.asm"

test:
	ld	sp, 0xffff

	call	testParseThruth

	; success
	xor	a
	halt

testParseThruth:
	ld	hl, .t1
	call	.true
	ld	hl, .t2
	call	.true
	ld	hl, .t3
	call	.true
	ld	hl, .t4
	call	.true
	ld	hl, .t5
	call	.true
	ld	hl, .t6
	call	.true
	ld	hl, .t7
	call	.true
	ld	hl, .t8
	call	.true

	ld	hl, .f1
	call	.false
	ld	hl, .f2
	call	.false
	ld	hl, .f3
	call	.false
	ld	hl, .f4
	call	.false
	ld	hl, .f5
	call	.false
	ld	hl, .f6
	call	.false

	ld	hl, .e1
	call	.error
	ret

.true:
	call	parseTruth
	jp	nz, fail
	or	a
	jp	z, fail
	jp	nexttest

.false:
	call	parseTruth
	jp	nz, fail
	or	a
	jp	nz, fail
	jp	nexttest

.error:
	call	parseTruth
	jp	z, fail
	jp	nexttest

.t1:	.db	"42", 0
.t2:	.db	"42+4=50-4", 0
.t3:	.db	"1<2", 0
.t4:	.db	"2>1", 0
.t5:	.db	"2>=1", 0
.t6:	.db	"2>=2", 0
.t7:	.db	"1<=2", 0
.t8:	.db	"2<=2", 0
.f1:	.db	"42-42", 0
.f2:	.db	"42+4=33+2", 0
.f3:	.db	"2<2", 0
.f4:	.db	"1>2", 0
.f5:	.db	"1>=2", 0
.f6:	.db	"2<=1", 0
.e1:	.db	"foo", 0

testNum:	.db 1

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
