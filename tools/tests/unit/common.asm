; *** requirements ***
; ascii.h
; core
; stdio
; lib/ari
; lib/fmt

testNum:	.db 1

STDIO_PUTC:
	out	(0), a
	cp	a
	ret

STDIO_GETC:
	jp	unsetZ

assertZ:
	ret	z
	ld	hl, .msg
	call	printstr
	jp	fail
.msg:
	.db	"Z not set", CR, LF, 0

assertNZ:
	ret	nz
	ld	hl, .msg
	call	printstr
	jp	fail
.msg:
	.db	"Z set", CR, LF, 0

; Assert that HL == DE
assertEQW:
	ld	a, h
	cp	d
	jr	nz, .fail
	ld	a, l
	cp	e
	ret	z
.fail:
	call	printHexPair
	call	printcrlf
	ex	de, hl
	call	printHexPair
	call	printcrlf
	ld	hl, .msg
	call	printstr
	jp	fail
.msg:
	.db	"HL != DE", CR, LF, 0

; Given a list of pointer to test data structures in HL and a pointer to a test
; routine in IX, call (IX) with HL pointing to the test structure until the list
; points to a zero. See testParseExpr in test_expr for an example usage.
testList:
	push	hl		; --> lvl 1
	call	intoHL
	ld	a, h
	or	l
	jr	z, .end
	call	callIX
	call	nexttest
	pop	hl		; <-- lvl 1
	inc	hl \ inc hl
	jr	testList
.end:
	pop	hl		; <-- lvl 1
	ret

nexttest:
	ld	a, (testNum)
	inc	a
	ld	(testNum), a
	ret

fail:
	ld	a, (testNum)
	halt
