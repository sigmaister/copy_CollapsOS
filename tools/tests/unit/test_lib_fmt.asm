jp	test

.inc "core.asm"
.inc "lib/util.asm"
.inc "lib/ari.asm"
.inc "lib/fmt.asm"

testNum:	.db 1

test:
	ld	sp, 0xffff

	call	testFmtDecimal
	call	testFmtDecimalS

	; success
	xor	a
	halt

testFmtDecimal:
	ld	ix, .t1
	call	.test
	ld	ix, .t2
	call	.test
	ld	ix, .t3
	call	.test
	ld	ix, .t4
	call	.test
	ld	ix, .t5
	call	.test
	ret
.test:
	ld	e, (ix)
	ld	d, (ix+1)
	ld	hl, sandbox
	call	fmtDecimal
	ld	hl, sandbox
	push	ix \ pop de
	inc	de \ inc de
	call	strcmp
	jp	nz, fail
	jp	nexttest
.t1:
	.dw 1234
	.db "1234", 0
.t2:
	.dw 9999
	.db "9999", 0
.t3:
	.dw 0
	.db "0", 0
.t4:
	.dw 0x7fff
	.db "32767", 0
.t5:
	.dw 0xffff
	.db "65535", 0

testFmtDecimalS:
	ld	ix, .t1
	call	.test
	ld	ix, .t2
	call	.test
	ret
.test:
	ld	e, (ix)
	ld	d, (ix+1)
	ld	hl, sandbox
	call	fmtDecimalS
	ld	hl, sandbox
	push	ix \ pop de
	inc	de \ inc de
	call	strcmp
	jp	nz, fail
	jp	nexttest
.t1:
	.dw 1234
	.db "1234", 0
.t2:
	.dw 0-1234
	.db "-1234", 0

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

