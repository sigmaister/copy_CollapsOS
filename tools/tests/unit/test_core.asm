jp	test

.inc "core.asm"

testNum:	.db 1

test:
	ld	hl, 0xffff
	ld	sp, hl

	; *** Just little z80 flags memo.
	and	a		; clear carry
	ld	hl, 100
	ld	de, 101
	sbc	hl, de
	jp	nc, fail	; carry is set
	call	nexttest

	and	a		; clear carry
	ld	hl, 101
	ld	de, 100
	sbc	hl, de
	jp	c, fail		; carry is reset
	call	nexttest

	ld	a, 1
	dec	a
	jp	m, fail		; positive
	dec	a
	jp	p, fail		; negative
	call	nexttest

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

nexttest:
	ld	a, (testNum)
	inc	a
	ld	(testNum), a
	ret

fail:
	ld	a, (testNum)
	halt
