; A dictionary entry has this structure:
; - 7b name (zero-padded)
; - 1b flags (bit 0: IMMEDIATE)
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

; Execute a list of atoms, which usually ends with EXIT.
; IY points to that list.
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

; The word was spawned from a definition word that has a DOES>. PFA+2 (right
; after the actual cell) is a link to the slot right after that DOES>.
; Therefore, what we need to do push the cell addr like a regular cell, then
; follow the link from the PFA, and then continue as a regular compiledWord.
doesWord:
	push	iy	; like a regular cell
	ld	l, (iy+2)
	ld	h, (iy+3)
	push	hl \ pop iy
	jr	compiledWord

; The IF word checks the stack for zero. If it's non-zero, it does nothing and
; allow compiledWord to continue.
; If it's zero, it tracksback RS, advance it until it finds a ELSE, a THEN, or
; an EXIT (not supposed to happen unless the IF is misconstructed). Whether
; it's a ELSE or THEN, the same thing happens: we resume execution after the
; ELSE/THEN. If it's a EXIT, we simply execute it.
ifWord:
	pop	hl
	ld	a, h
	or	l
	jp	nz, exit	; non-zero, continue
	; Zero, seek ELSE, THEN or EXIT. Continue to elseWord

; If a ELSE word is executed, it means that the preceding IF had a non-zero
; condition and continued execution. This means that upon encountering an ELSE,
; we must search for a THEN or an EXIT.
; To simplify implementation and share code with ifWord, we also match ELSE,
; which is only possible in malformed construct. Therefore "IF ELSE ELSE" is
; valid and interpreted as "IF ELSE THEN".
elseWord:
	; to save processing, we test EXIT, ELSE and THEN in the order they
	; appear, address-wise. This way, we don't need to push/pop HL: we can
	; SUB the difference between the words and check for zeroes.
	call	popRS
	; We need to save that IP somewhere. Let it be BC
	ld	b, h
	ld	c, l
.loop:
	; Whether there's a match or not, we will resume the operation at IP+2,
	; which means that we have to increase BC anyways. Let's do it now.
	inc	bc \ inc bc
	call	intoHL
	or	a		; clear carry
	ld	de, EXIT
	sbc	hl, de
	jp	z, exit
	; Not EXIT, let's continue with ELSE. No carry possible because EXIT
	; is first word. No need to clear.
	ld	de, ELSE-EXIT
	sbc	hl, de
	jr	c, .nomatch	; A word between EXIT and ELSE. No match.
	jr	z, .match	; We have a ELSE
	; Let's try with THEN. Again, no carry possible, C cond was handled.
	ld	de, THEN-ELSE
	sbc	hl, de
	jr	z, .match	; We have a THEN
.nomatch:
	; Nothing matched, which means that we need to continue looking.
	; BC is already IP+2
	ld	h, b
	ld	l, c
	jr	.loop
.match:
	; Matched a ELSE or a THEN, which means we need to continue executing
	; word from IP+2, which is already in BC.
	push	bc \ pop iy
	jp	compiledWord

; This word does nothing. It's never going to be executed unless the wordlist
; is misconstructed.
thenWord:
	jp	exit

; This is not a word, but a number literal. This works a bit differently than
; others: PF means nothing and the actual number is placed next to the
; numberWord reference in the compiled word list. What we need to do to fetch
; that number is to play with the Return stack: We pop it, read the number, push
; it to the Parameter stack and then push an increase Interpreter Pointer back
; to RS.
numberWord:
	call	popRS
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	inc	hl
	call	pushRS
	push	de
	jp	exit
NUMBER:
	.dw	numberWord

; Similarly to numberWord, this is not a real word, but a string literal.
; Instead of being followed by a 2 bytes number, it's followed by a
; null-terminated string. This is not expected to be called in a regular
; context. Only words expecting those literals will look for them. This is why
; the litWord triggers abort.
litWord:
	call	popRS
	call	intoHL
	call	printstr	; let's print the word before abort.
	ld	hl, .msg
	call	printstr
	jp	abort
.msg:
	.db "undefined word", 0
LIT:
	.dw	litWord

; ( R:I -- )
	.db ";"
	.fill 7
	.dw 0
EXIT:
	.dw nativeWord
; When we call the EXIT word, we have to do a "double exit" because our current
; Interpreter pointer is pointing to the word *next* to our EXIT reference when,
; in fact, we want to continue processing the one above it.
	call	popRS
exit:
	; Before we continue: is SP within bounds?
	call	chkPS
	; we're good
	call	popRS
	; We have a pointer to a word
	push	hl \ pop iy
	jp	compiledWord

; ( R:I -- )
	.db "QUIT"
	.fill 4
	.dw EXIT
QUIT:
	.dw nativeWord
quit:
	jp	forthRdLine

	.db "ABORT"
	.fill 3
	.dw QUIT
ABORT:
	.dw nativeWord
abort:
	; Reinitialize PS (RS is reinitialized in forthInterpret
	ld	sp, (INITIAL_SP)
	jp	forthRdLine

	.db "BYE"
	.fill 5
	.dw ABORT
BYE:
	.dw nativeWord
	; Goodbye Forth! Before we go, let's restore the stack
	ld	sp, (INITIAL_SP)
	; unwind stack underflow buffer
	pop	af \ pop af \ pop af
	; success
	xor	a
	ret

; ( c -- )
	.db "EMIT"
	.fill 4
	.dw BYE
EMIT:
	.dw nativeWord
	pop	hl
	ld	a, l
	call	stdioPutC
	jp	exit

; ( addr -- )
	.db "EXECUTE"
	.db 0
	.dw EMIT
EXECUTE:
	.dw nativeWord
	pop	iy	; is a wordref
executeCodeLink:
	ld	l, (iy)
	ld	h, (iy+1)
	; HL points to code pointer
	inc	iy
	inc	iy
	; IY points to PFA
	jp	(hl)	; go!

	.db ":"
	.fill 7
	.dw EXECUTE
DEFINE:
	.dw nativeWord
	call	entryhead
	ld	de, compiledWord
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	; At this point, we've processed the name literal following the ':'.
	; What's next? We have, in IP, a pointer to words that *have already
	; been compiled by INTERPRET*. All those bytes will be copied as-is.
	; All we need to do is to know how many bytes to copy. To do so, we
	; skip compwords until EXIT is reached.
	ld	(HERE), hl	; where we write compwords.
	ld	l, (ix)
	ld	h, (ix+1)
.loop:
	call	HLPointsEXIT
	jr	z, .loopend
	call	compSkip
	jr	.loop
.loopend:
	; At this point, HL points to EXIT compword. We'll copy it too.
	; We'll use LDIR. BC will be RSTOP-OLDRSTOP+2
	ld	e, (ix)
	ld	d, (ix+1)
	inc	hl \ inc hl	; our +2
	or	a		; clear carry
	sbc	hl, de
	ld	b, h
	ld	c, l
	; BC has proper count
	ex	de, hl		; HL is our source (old RS' TOS)
	ld	de, (HERE)	; and DE is our dest
	ldir			; go!
	; HL has our new RS' TOS
	ld	(ix), l
	ld	(ix+1), h
	ld	(HERE), de	; update HERE
	jp	exit

	.db "DOES>"
	.fill 3
	.dw DEFINE
DOES:
	.dw nativeWord
	; We run this when we're in an entry creation context. Many things we
	; need to do.
	; 1. Change the code link to doesWord
	; 2. Leave 2 bytes for regular cell variable.
	; 3. Get the Interpreter pointer from the stack and write this down to
	;    entry PFA+2.
	; 3. exit. Because we've already popped RS, a regular exit will abort
	;    colon definition, so we're good.
	ld	iy, (CURRENT)
	ld	hl, doesWord
	call	wrCompHL
	inc	iy \ inc iy		; cell variable space
	call	popRS
	call	wrCompHL
	ld	(HERE), iy
	jp	exit

; ( -- c )
	.db "KEY"
	.fill 5
	.dw DOES
KEY:
	.dw nativeWord
	call	stdioGetC
	ld	h, 0
	ld	l, a
	push	hl
	jp	exit

	.db "INTERPR"
	.db 0
	.dw KEY
INTERPRET:
	.dw nativeWord
interpret:
	ld	iy, COMPBUF
.loop:
	call	readword
	jr	nz, .end
	call	compile
	jr	.loop
.end:
	ld	hl, QUIT
	call	wrCompHL
	ld	iy, COMPBUF
	jp	compiledWord

	.db "CREATE"
	.fill 2
	.dw INTERPRET
CREATE:
	.dw nativeWord
	call	entryhead
	jp	nz, quit
	ld	de, cellWord
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	ld	(HERE), hl
	jp	exit

	.db "HERE"
	.fill 4
	.dw CREATE
HERE_:	; Caution: conflicts with actual variable name
	.dw sysvarWord
	.dw HERE

	.db "CURRENT"
	.db 0
	.dw HERE_
CURRENT_:
	.dw sysvarWord
	.dw CURRENT

; ( n -- )
	.db "."
	.fill 7
	.dw CURRENT_
DOT:
	.dw nativeWord
	pop	de
	; We check PS explicitly because it doesn't look nice to spew gibberish
	; before aborting the stack underflow.
	call	chkPS
	call	pad
	call	fmtDecimalS
	call	printstr
	jp	exit

; ( n a -- )
	.db "!"
	.fill 7
	.dw DOT
STORE:
	.dw nativeWord
	pop	iy
	pop	hl
	ld	(iy), l
	ld	(iy+1), h
	jp	exit

; ( a -- n )
	.db "@"
	.fill 7
	.dw STORE
FETCH:
	.dw nativeWord
	pop	hl
	call	intoHL
	push	hl
	jp	exit

; ( a b -- b a )
	.db "SWAP"
	.fill 4
	.dw FETCH
SWAP:
	.dw nativeWord
	pop	hl
	ex	(sp), hl
	push	hl
	jp	exit

; ( a -- a a )
	.db "DUP"
	.fill 5
	.dw SWAP
DUP:
	.dw nativeWord
	pop	hl
	push	hl
	push	hl
	jp	exit

; ( a b -- a b a )
	.db "OVER"
	.fill 4
	.dw DUP
OVER:
	.dw nativeWord
	pop	hl	; B
	pop	de	; A
	push	de
	push	hl
	push	de
	jp	exit

; ( a b -- c ) A + B
	.db "+"
	.fill 7
	.dw OVER
PLUS:
	.dw nativeWord
	pop	hl
	pop	de
	add	hl, de
	push	hl
	jp	exit

; ( a b -- c ) A - B
	.db "-"
	.fill 7
	.dw PLUS
MINUS:
	.dw nativeWord
	pop	de		; B
	pop	hl		; A
	or	a		; reset carry
	sbc	hl, de
	push	hl
	jp	exit

; ( a b -- c ) A * B
	.db "*"
	.fill 7
	.dw MINUS
MULT:
	.dw nativeWord
	pop	de
	pop	bc
	call	multDEBC
	push	hl
	jp	exit

; ( a b -- c ) A / B
	.db "/"
	.fill 7
	.dw MULT
DIV:
	.dw nativeWord
	pop	de
	pop	hl
	call	divide
	push	bc
	jp	exit

	.db "IF"
	.fill 6
	.dw DIV
IF:
	.dw ifWord

	.db "ELSE"
	.fill 4
	.dw IF
ELSE:
	.dw elseWord

	.db "THEN"
	.fill 4
	.dw ELSE
THEN:
	.dw thenWord

; End of native words

; ( a -- )
; @ .
	.db "?"
	.fill 7
	.dw THEN
FETCHDOT:
	.dw compiledWord
	.dw FETCH
	.dw DOT
	.dw EXIT

; ( n a -- )
; SWAP OVER @ + SWAP !
	.db "+!"
	.fill 6
	.dw FETCHDOT
STOREINC:
	.dw compiledWord
	.dw SWAP
	.dw OVER
	.dw FETCH
	.dw PLUS
	.dw SWAP
	.dw STORE
	.dw EXIT

; ( n -- )
; HERE +!
	.db "ALLOT"
	.fill 3
	.dw STOREINC
ALLOT:
	.dw compiledWord
	.dw HERE_
	.dw STOREINC
	.dw EXIT

; CREATE 2 ALLOT
	.db "VARIABL"
	.db 0
	.dw ALLOT
VARIABLE:
	.dw compiledWord
	.dw CREATE
	.dw NUMBER
	.dw 2
	.dw ALLOT
	.dw EXIT

; ( n -- )
; CREATE HERE @ ! DOES> @
	.db "CONSTAN"
	.db 0
	.dw VARIABLE
CONSTANT:
	.dw compiledWord
	.dw CREATE
	.dw HERE_
	.dw FETCH
	.dw STORE
	.dw DOES
	.dw FETCH
	.dw EXIT
