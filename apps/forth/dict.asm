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
	ld	de, EXIT+CODELINK_OFFSET
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
EXIT:
	.db ";"
	.fill 7
	.dw 0
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
QUIT:
	.db "QUIT", 0, 0, 0, 0
	.dw EXIT
	.dw nativeWord
quit:
	jp	forthRdLine

ABORT:
	.db "ABORT", 0, 0, 0
	.dw QUIT
	.dw nativeWord
abort:
	; Reinitialize PS (RS is reinitialized in forthInterpret
	ld	sp, (INITIAL_SP)
	jp	forthRdLine

BYE:
	.db "BYE"
	.fill 5
	.dw ABORT
	.dw nativeWord
	; Goodbye Forth! Before we go, let's restore the stack
	ld	sp, (INITIAL_SP)
	; unwind stack underflow buffer
	pop	af \ pop af \ pop af
	; success
	xor	a
	ret

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

DEFINE:
	.db ":"
	.fill 7
	.dw EXECUTE
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
	; Let's save old RS TOS
	ld	e, (ix)
	ld	d, (ix+1)
.loop:
	call	RSIsEXIT
	jr	z, .loopend
	call	compSkip
	jr	.loop
.loopend:
	; At this point, RS' TOS points to EXIT compword. We'll copy it too.
	; We'll use LDIR. BC will be RSTOP-OLDRSTOP+2
	ld	l, (ix)
	ld	h, (ix+1)
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

DOES:
	.db "DOES>", 0, 0, 0
	.dw DEFINE
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
	ld	de, CODELINK_OFFSET
	add	iy, de
	ld	hl, doesWord
	call	wrCompHL
	inc	iy \ inc iy		; cell variable space
	call	popRS
	call	wrCompHL
	ld	(HERE), iy
	jp	exit

; ( -- c )
KEY:
	.db "KEY"
	.fill 5
	.dw DOES
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
	ld	iy, COMPBUF
.loop:
	call	readword
	jr	nz, .end
	call	compile
	jr	.loop
.end:
	ld	hl, QUIT+CODELINK_OFFSET
	call	wrCompHL
	ld	iy, COMPBUF
	jp	compiledWord

CREATE:
	.db "CREATE", 0, 0
	.dw INTERPRET
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

HERE_:	; Caution: conflicts with actual variable name
	.db "HERE"
	.fill 4
	.dw CREATE
	.dw sysvarWord
	.dw HERE

CURRENT_:
	.db "CURRENT", 0
	.dw HERE_
	.dw sysvarWord
	.dw CURRENT

; ( n -- )
DOT:
	.db "."
	.fill 7
	.dw CURRENT_
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

; ( a b -- b a )
SWAP:
	.db "SWAP"
	.fill 4
	.dw FETCH
	.dw nativeWord
	pop	hl
	ex	(sp), hl
	push	hl
	jp	exit

; ( a -- a a )
DUP:
	.db "DUP"
	.fill 5
	.dw SWAP
	.dw nativeWord
	pop	hl
	push	hl
	push	hl
	jp	exit

; ( a b -- a b a )
OVER:
	.db "OVER"
	.fill 4
	.dw DUP
	.dw nativeWord
	pop	hl	; B
	pop	de	; A
	push	de
	push	hl
	push	de
	jp	exit

; ( a b -- c ) A + B
PLUS:
	.db "+"
	.fill 7
	.dw OVER
	.dw nativeWord
	pop	hl
	pop	de
	add	hl, de
	push	hl
	jp	exit

; ( a b -- c ) A - B
MINUS:
	.db "-"
	.fill 7
	.dw PLUS
	.dw nativeWord
	pop	de		; B
	pop	hl		; A
	or	a		; reset carry
	sbc	hl, de
	push	hl
	jp	exit

; ( a b -- c ) A * B
MULT:
	.db "*"
	.fill 7
	.dw MINUS
	.dw nativeWord
	pop	de
	pop	bc
	call	multDEBC
	push	hl
	jp	exit

; ( a b -- c ) A / B
DIV:
	.db "/"
	.fill 7
	.dw MULT
	.dw nativeWord
	pop	de
	pop	hl
	call	divide
	push	bc
	jp	exit

IF:
	.db "IF"
	.fill 6
	.dw DIV
	.dw ifWord

ELSE:
	.db "ELSE"
	.fill 4
	.dw IF
	.dw elseWord

THEN:
	.db "THEN"
	.fill 4
	.dw ELSE
	.dw thenWord

; End of native words

; ( a -- )
; @ .
FETCHDOT:
	.db "?"
	.fill 7
	.dw THEN
	.dw compiledWord
	.dw FETCH+CODELINK_OFFSET
	.dw DOT+CODELINK_OFFSET
	.dw EXIT+CODELINK_OFFSET

; ( n a -- )
; SWAP OVER @ + SWAP !
STOREINC:
	.db "+!"
	.fill 6
	.dw FETCHDOT
	.dw compiledWord
	.dw SWAP+CODELINK_OFFSET
	.dw OVER+CODELINK_OFFSET
	.dw FETCH+CODELINK_OFFSET
	.dw PLUS+CODELINK_OFFSET
	.dw SWAP+CODELINK_OFFSET
	.dw STORE+CODELINK_OFFSET
	.dw EXIT+CODELINK_OFFSET

; ( n -- )
; HERE +!
ALLOT:
	.db "ALLOT", 0, 0, 0
	.dw STOREINC
	.dw compiledWord
	.dw HERE_+CODELINK_OFFSET
	.dw STOREINC+CODELINK_OFFSET
	.dw EXIT+CODELINK_OFFSET

; CREATE 2 ALLOT
VARIABLE:
	.db "VARIABLE"
	.dw ALLOT
	.dw compiledWord
	.dw CREATE+CODELINK_OFFSET
	.dw NUMBER
	.dw 2
	.dw ALLOT+CODELINK_OFFSET
	.dw EXIT+CODELINK_OFFSET

; ( n -- )
; CREATE HERE @ ! DOES> @
CONSTANT:
	.db "CONSTANT"
	.dw VARIABLE
	.dw compiledWord
	.dw CREATE+CODELINK_OFFSET
	.dw HERE_+CODELINK_OFFSET
	.dw FETCH+CODELINK_OFFSET
	.dw STORE+CODELINK_OFFSET
	.dw DOES+CODELINK_OFFSET
	.dw FETCH+CODELINK_OFFSET
	.dw EXIT+CODELINK_OFFSET
