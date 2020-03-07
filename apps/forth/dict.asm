; A dictionary entry has this structure:
; - 8b name (zero-padded)
; - 2b prev pointer
; - 2b code pointer
; - Parameter field area (PFA)
;
; The code pointer point to "word routines". These routines expect to be called
; with IY pointing to the PFA. They themselves are expected to end by jumping
; to the address at the top of the Return Stack. They will usually do so with
; "jp exit".

; Execute a word containing native code at its PFA
nativeWord:
	jp	(iy)

; Execute a compiled word containing a list of references to other words,
; usually ended by a reference to EXIT.
; A reference to a word in a compiledWord section is *not* a direct reference,
; but a word+CODELINK_OFFSET reference. Therefore, for a code link "link",
; (link) is the routine to call.
compiledWord:
	push	iy \ pop hl
	inc	hl
	inc	hl
	; HL points to next Interpreter pointer.
	call	pushRS
	ld	l, (iy)
	ld	h, (iy+1)
	push	hl \ pop iy
	; IY points to code link
	jp	executeCodeLink

; ( R:I -- )
EXIT:
	.db "EXIT", 0, 0, 0, 0
	.dw 0
	.dw nativeWord
; When we call the EXIT word, we have to do a "double exit" because our current
; Interpreter pointer is pointing to the word *next* to our EXIT reference when,
; in fact, we want to continue processing the one above it.
	call	popRS
exit:
	call	popRS
	; We have a pointer to a word
	push	hl \ pop iy
	jp	compiledWord

BYE:
	.db "BYE"
	.fill 5
	.dw EXIT
	.dw nativeWord
	ld	hl, FLAGS
	set	FLAG_ENDPGM, (hl)
	jp	exit

; ( c -- )
EMIT:
	.db "EMIT", 0, 0, 0, 0
	.dw BYE
	.dw nativeWord
	pop	hl
	ld	a, l
	call	stdioPutC
	jp	exit

; ( addr -- )
EXECUTE:
	.db "EXECUTE", 0
	.dw EMIT
	.dw nativeWord
	pop	iy	; Points to word_offset
	ld	de, CODELINK_OFFSET
	add	iy, de
executeCodeLink:
	ld	l, (iy)
	ld	h, (iy+1)
	; HL points to code pointer
	inc	iy
	inc	iy
	; IY points to PFA
	jp	(hl)	; go!

; ( -- c )
KEY:
	.db "KEY", 0, 0, 0, 0, 0
	.dw EXECUTE
	.dw nativeWord
	call	stdioGetC
	ld	h, 0
	ld	l, a
	push	hl
	jp	exit

INTERPRET:
	.db "INTERPRE"
	.dw KEY
	.dw nativeWord
interpret:
	call	pad
	push	hl \ pop iy
	call	stdioReadLine
	ld	(INPUTPOS), hl
.loop:
	call	readword
	jp	nz, .loopend
	call	compile
	jr	nz, .notfound
	jr	.loop
.loopend:
	call	compileExit
	call	pad
	push	hl \ pop iy
	jp	compiledWord
.notfound:
	ld	hl, .msg
	call	printstr
	jp	exit
.msg:
	.db	"not found", 0

; ( n -- )
DOT:
	.db "."
	.fill 7
	.dw INTERPRET
	.dw nativeWord
	pop	de
	call	pad
	call	fmtDecimalS
	call	printstr
	jp	exit
