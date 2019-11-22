jp	test

.inc "core.asm"
.inc "lib/ari.asm"

testNum:	.db 1

test:
	ld	sp, 0xffff

	ld	de, 12
	ld	bc, 4
	call	multDEBC
	ld	a, l
	cp	48
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




