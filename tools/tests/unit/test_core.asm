.equ foo 456	; AFTER_ORG should not get that value
.org 0x1234
.equ AFTER_ORG	@
.org 0

jp	test

.inc "ascii.h"
.inc "core.asm"
.inc "lib/ari.asm"
.inc "lib/fmt.asm"
.inc "stdio.asm"
.inc "common.asm"

dummyLabel:

.equ	dummyLabel	0x42

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

	; Test that .equ can override label
	ld	de, 0x42
	ld	hl, dummyLabel
	call	assertEQW
	call	nexttest

	; test that "@" is updated by a .org directive
	ld	hl, AFTER_ORG
	ld	de, 0x1234
	call	assertEQW
	call	nexttest

	; test that AND affects the Z flag
	ld	a, 0x69
	and	0x80
	call	assertZ
	call	nexttest

	; success
	xor	a
	halt

STDIO_RAMSTART:
