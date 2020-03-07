; A dictionary entry has this structure:
; - 8b name (zero-padded)
; - 2b prev pointer
; - 2b code pointer
; - Parameter field (PF)
;
; The code pointer point to "word routines". These routines expect to be called
; with IY pointing to the PF. They themselves are expected to end by jumping
; to the address at the top of the Return Stack. They will usually do so with
; "jp exit".

; Execute a word containing native code at its PF address (PFA)
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

; Pushes the PFA directly
cellWord:
	push	iy
	jp	exit

; Pushes the address in the first word of the PF
sysvarWord:
	ld	l, (iy)
	ld	h, (iy+1)
	push	hl
	jp	exit

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

; ( R:I -- )
QUIT:
	.db "QUIT", 0, 0, 0, 0
	.dw EXIT
	.dw nativeWord
quit:
	ld	hl, FLAGS
	set	FLAG_QUITTING, (hl)
	jp	exit

BYE:
	.db "BYE"
	.fill 5
	.dw QUIT
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
	.db "KEY"
	.fill 5
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
	call	readword
	jp	nz, quit
	ld	iy, COMPBUF
	call	compile
	jp	nz, .notfound
	ld	hl, EXIT+CODELINK_OFFSET
	ld	(iy), l
	ld	(iy+1), h
	ld	iy, COMPBUF
	jp	compiledWord
.notfound:
	ld	hl, .msg
	call	printstr
	jp	quit
.msg:
	.db	"not found", 0

CREATE:
	.db "CREATE", 0, 0
	.dw INTERPRET
	.dw nativeWord
	call	readword
	jp	nz, exit
	ld	de, (HERE)
	call	strcpy
	ex	de, hl		; (HERE) now in HL
	ld	de, (CURRENT)
	ld	(CURRENT), hl
	ld	a, NAMELEN
	call	addHL
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	ld	de, cellWord
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	ld	(HERE), hl
	jp	exit

HERE_:	; Caution: conflicts with actual variable name
	.db "HERE"
	.fill 4
	.dw CREATE
	.dw sysvarWord
	.dw HERE

; ( n -- )
DOT:
	.db "."
	.fill 7
	.dw HERE_
	.dw nativeWord
	pop	de
	call	pad
	call	fmtDecimalS
	call	printstr
	jp	exit

; ( n a -- )
STORE:
	.db "!"
	.fill 7
	.dw DOT
	.dw nativeWord
	pop	iy
	pop	hl
	ld	(iy), l
	ld	(iy+1), h
	jp	exit

; ( a -- n )
FETCH:
	.db "@"
	.fill 7
	.dw STORE
	.dw nativeWord
	pop	hl
	call	intoHL
	push	hl
	jp	exit
