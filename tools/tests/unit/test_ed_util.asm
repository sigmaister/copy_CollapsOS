jp	test

.inc "ed/util.asm"

test:
	ld	sp, 0xffff

	; *** cpHLDE ***
	ld	hl, 0x42
	ld	de, 0x42
	call	cpHLDE
	jp	nz, fail
	jp	c, fail
	call	nexttest

	ld	de, 0x4242
	call	cpHLDE
	jp	z, fail
	jp	nc, fail
	call	nexttest

	ld	hl, 0x4243
	call	cpHLDE
	jp	z, fail
	jp	c, fail
	call	nexttest

	; success
	xor	a
	halt

testNum:	.db 1

nexttest:
	ld	a, (testNum)
	inc	a
	ld	(testNum), a
	ret

fail:
	ld	a, (testNum)
	halt
