jp	runTests

.inc "err.h"
.inc "core.asm"
.inc "parse.asm"
.inc "zasm/const.asm"
.inc "lib/util.asm"
.inc "zasm/util.asm"
.inc "lib/parse.asm"
.inc "zasm/parse.asm"
.inc "zasm/expr.asm"
.equ	INS_RAMSTART	RAMSTART
.inc "zasm/instr.asm"

zasmGetPC:
	ret

zasmIsFirstPass:
	jp	unsetZ

readWord:
readComma:
symFindVal:
	xor	a
	ret

ioPutB:
	push	hl
	ld	hl, SPITBOWL
	push	af
	ld	a, (SPITCNT)
	call	addHL
	inc	a
	ld	(SPITCNT), a
	pop	af
	ld	(hl), a
	pop	hl
	cp	a
	ret

runTests:
	call	testMatchArg
	call	testSpitUpcode
	xor	a
	halt

testSpitUpcode:
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
	; init spitbowl
	xor	a
	ld	(SPITCNT), a
	ld	(SPITBOWL), a
	ld	(SPITBOWL+1), a
	ld	(SPITBOWL+2), a
	ld	(SPITBOWL+3), a
	push	ix \ pop de
	call	intoDE
	ld	a, (ix+2)
	ld	(INS_CURARG1), a
	ld	a, (ix+3)
	ld	(INS_CURARG1+1), a
	ld	a, (ix+4)
	ld	(INS_CURARG1+2), a
	ld	a, (ix+5)
	ld	(INS_CURARG2), a
	ld	a, (ix+6)
	ld	(INS_CURARG2+1), a
	ld	a, (ix+7)
	ld	(INS_CURARG2+2), a
	call	spitUpcode
	jp	nz, fail
	ld	a, (SPITCNT)
	cp	(ix+8)
	jp	nz, fail
	ld	a, (SPITBOWL)
	cp	(ix+9)
	jp	nz, fail
	ld	a, (SPITBOWL+1)
	cp	(ix+10)
	jp	nz, fail
	ld	a, (SPITBOWL+2)
	cp	(ix+11)
	jp	nz, fail
	ld	a, (SPITBOWL+3)
	cp	(ix+12)
	jp	nz, fail
	jp	nexttest

; Test data is a argspec pointer in instrTBl followed by 2*3 bytes of CURARG
; followed by the expected spit, 1 byte cnt + 4 bytes spits.
.t1:
	.dw	instrTBl+17*6	; CCF
	.db	0, 0, 0
	.db	0, 0, 0
	.db	1, 0x3f, 0, 0, 0
.t2:
	.dw	instrTBl+10*6	; AND (IX+0x42)
	.db	'x', 0x42, 0
	.db	0, 0, 0
	.db	3, 0xdd, 0xa6, 0x42, 0
.t3:
	.dw	instrTBl+13*6	; BIT 4, (IX+3)
	.db	'N', 4, 0
	.db	'x', 3, 0
	.db	4, 0xdd, 0xcb, 0x03, 0x66
.t4:
	.dw	instrTBl+18*6	; CP (IX+5)
	.db	'x', 5, 0
	.db	0, 0, 0
	.db	3, 0xdd, 0xbe, 0x05, 0
.t5:
	.dw	instrTBl+4*6	; ADD A, (IX+5)
	.db	'A', 0, 0
	.db	'x', 5, 0
	.db	3, 0xdd, 0x86, 0x05, 0

testMatchArg:
	ld	iy, .t1
	call	.test
	ret

.test:
	ld	hl, SPITBOWL
	ld	a, (iy+2)
	ld	(hl), a
	push	iy \ pop de
	call	intoDE
	push	de \ pop ix
	ld	a, (ix+1)
	call	matchArg
	jp	nz, fail
	ld	a, (iy+3)
	ld	(hl), a
	ld	a, (ix+2)
	call	matchArg
	jp	nz, fail
	jp	nexttest

; Test data is argspec pointer followed by two bytes: first bytes of our two
; CURARG.
.t1:
	.dw	instrTBl+4*6	; ADD A, (IX)
	.db	'A', 'x'

nexttest:
	ld	a, (testNum)
	inc	a
	ld	(testNum), a
	ret

fail:
	ld	a, (testNum)
	halt

testNum:	.db 1

SPITCNT:
	.db 0
SPITBOWL:
	.db 0, 0, 0, 0

DIREC_LASTVAL:
	.db 0, 0

RAMSTART:
