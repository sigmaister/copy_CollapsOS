jp	test

.inc "core.asm"
.inc "str.asm"
.inc "lib/util.asm"
.inc "zasm/util.asm"

testNum:	.db 1
sFoo:		.db "foo", 0

test:
	ld	hl, 0xffff
	ld	sp, hl

	ld	hl, sFoo
	call	strlen
	cp	3
	jp	nz, fail
	call	nexttest

	; success
	xor	a
	halt

nexttest:
	ld	a, (testNum)
	inc	a
	ld	(testNum), a
	ret

fail:
	ld	a, (testNum)
	halt



