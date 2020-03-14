; A dictionary entry has this structure:
; - 7b name (zero-padded)
; - 2b prev pointer
; - 1b flags (bit 0: IMMEDIATE. bit 1: UNWORD)
; - 2b code pointer
; - Parameter field (PF)
;
; The code pointer point to "word routines". These routines expect to be called
; with IY pointing to the PF. They themselves are expected to end by jumping
; to the address at (IP). They will usually do so with "jp next".
;
; That's for "regular" words (words that are part of the dict chain). There are
; also "special words", for example NUMBER, LIT, FBR, that have a slightly
; different structure. They're also a pointer to an executable, but as for the
; other fields, the only one they have is the "flags" field.

; This routine is jumped to at the end of every word. In it, we jump to current
; IP, but we also take care of increasing it my 2 before jumping
next:
	; Before we continue: are stacks within bounds?
	call	chkPSRS
	ld	de, (IP)
	ld	h, d
	ld	l, e
	inc	de \ inc de
	ld	(IP), de
	; HL is an atom list pointer. We need to go into it to have a wordref
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	push	de
	jp	EXECUTE+2


; Execute a word containing native code at its PF address (PFA)
nativeWord:
	jp	(iy)

; Execute a list of atoms, which always end with EXIT.
; IY points to that list. What do we do:
; 1. Push current IP to RS
; 2. Set new IP to the second atom of the list
; 3. Execute the first atom of the list.
compiledWord:
	ld	hl, (IP)
	call	pushRS
	push	iy \ pop hl
	inc	hl
	inc	hl
	ld	(IP), hl
	; IY still is our atom reference...
	ld	l, (iy)
	ld	h, (iy+1)
	push	hl	; argument for EXECUTE
	jp	EXECUTE+2

; Pushes the PFA directly
cellWord:
	push	iy
	jp	next

; Pushes the address in the first word of the PF
sysvarWord:
	ld	l, (iy)
	ld	h, (iy+1)
	push	hl
	jp	next

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

; This is not a word, but a number literal. This works a bit differently than
; others: PF means nothing and the actual number is placed next to the
; numberWord reference in the compiled word list. What we need to do to fetch
; that number is to play with the IP.
numberWord:
	ld	hl, (IP)	; (HL) is out number
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	inc	hl
	ld	(IP), hl	; advance IP by 2
	push	de
	jp	next

	.db	0b10		; Flags
NUMBER:
	.dw	numberWord

; Similarly to numberWord, this is not a real word, but a string literal.
; Instead of being followed by a 2 bytes number, it's followed by a
; null-terminated string. This is not expected to be called in a regular
; context. Only words expecting those literals will look for them. This is why
; the litWord triggers abort.
litWord:
	ld	hl, (IP)
	call	printstr	; let's print the word before abort.
	ld	hl, .msg
	call	printstr
	jp	abort
.msg:
	.db "undefined word", 0

	.db	0b10		; Flags
LIT:
	.dw	litWord

; Pop previous IP from Return stack and execute it.
; ( R:I -- )
	.db	"EXIT"
	.fill	3
	.dw	0
	.db	0
EXIT:
	.dw nativeWord
	call	popRS
	ld	(IP), hl
	jp	next

; ( R:I -- )
	.db "QUIT"
	.fill 3
	.dw EXIT
	.db 0
QUIT:
	.dw nativeWord
quit:
	jp	forthRdLine

	.db "ABORT"
	.fill 2
	.dw QUIT
	.db 0
ABORT:
	.dw nativeWord
abort:
	; Reinitialize PS (RS is reinitialized in forthInterpret)
	ld	sp, (INITIAL_SP)
	jp	forthRdLineNoOk
ABORTREF:
	.dw ABORT

	.db "BYE"
	.fill 4
	.dw ABORT
	.db 0
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
	.fill 3
	.dw BYE
	.db 0
EMIT:
	.dw nativeWord
	pop	hl
	ld	a, l
	call	stdioPutC
	jp	next

; ( c port -- )
	.db "PC!"
	.fill 4
	.dw EMIT
	.db 0
PSTORE:
	.dw nativeWord
	pop	bc
	pop	hl
	out	(c), l
	jp	next

; ( port -- c )
	.db "PC@"
	.fill 4
	.dw PSTORE
	.db 0
PFETCH:
	.dw nativeWord
	pop	bc
	ld	h, 0
	in	l, (c)
	push	hl
	jp	next

; ( addr -- )
	.db "EXECUTE"
	.dw PFETCH
	.db 0
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


	.db	";"
	.fill	6
	.dw	EXECUTE
	.db	0
ENDDEF:
	.dw	nativeWord
	jp	EXIT+2

	.db ":"
	.fill 6
	.dw ENDDEF
	.db 0
DEFINE:
	.dw nativeWord
	call	entryhead
	ld	de, compiledWord
	call	DEinHL
	; At this point, we've processed the name literal following the ':'.
	; What's next? We have, in IP, a pointer to words that *have already
	; been compiled by INTERPRET*. All those bytes will be copied as-is.
	; All we need to do is to know how many bytes to copy. To do so, we
	; skip compwords until EXIT is reached.
	ex	de, hl		; DE is our dest
	ld	(HERE), de	; update HERE
	ld	hl, (IP)
.loop:
	push	de		; --> lvl 1
	ld	de, ENDDEF
	call	HLPointsDE
	pop	de		; <-- lvl 1
	jr	z, .loopend
	call	compSkip
	jr	.loop
.loopend:
	; skip EXIT
	inc	hl \ inc hl
	; We have out end offset. Let's get our offset
	ld	de, (IP)
	or	a		; clear carry
	sbc	hl, de
	; HL is our copy count.
	ld	b, h
	ld	c, l
	ld	hl, (IP)
	ld	de, (HERE)	; recall dest
	; copy!
	ldir
	ld	(IP), hl
	ld	(HERE), de
	jp	next


	.db "DOES>"
	.fill 2
	.dw DEFINE
	.db 0
DOES:
	.dw nativeWord
	; We run this when we're in an entry creation context. Many things we
	; need to do.
	; 1. Change the code link to doesWord
	; 2. Leave 2 bytes for regular cell variable.
	; 3. Write down IP+2 to entry.
	; 3. exit. we're done here.
	ld	iy, (CURRENT)
	ld	hl, doesWord
	call	wrCompHL
	inc	iy \ inc iy		; cell variable space
	ld	hl, (IP)
	call	wrCompHL
	ld	(HERE), iy
	jp	EXIT+2


	.db "IMMEDIA"
	.dw DOES
	.db 0
IMMEDIATE:
	.dw nativeWord
	ld	hl, (CURRENT)
	dec	hl
	set	FLAG_IMMED, (hl)
	jp	next

; ( n -- )
	.db "LITERAL"
	.dw IMMEDIATE
	.db 1		; IMMEDIATE
LITERAL:
	.dw nativeWord
	ld	hl, (HERE)
	ld	de, NUMBER
	call	DEinHL
	pop	de		; number from stack
	call	DEinHL
	ld	(HERE), hl
	jp	next


	.db	"'"
	.fill	6
	.dw	LITERAL
	.db	0
APOS:
	.dw	nativeWord
	call	readLITBOS
	call	find
	jr	nz, .notfound
	push	de
	jp	next
.notfound:
	ld	hl, .msg
	call	printstr
	jp	abort
.msg:
	.db	"word not found", 0

	.db	"[']"
	.fill	4
	.dw	APOS
	.db	0b01		; IMMEDIATE
APOSI:
	.dw	nativeWord
	call	readword
	call	find
	jr	nz, .notfound
	ld	hl, (HERE)
	push	de		; --> lvl 1
	ld	de, NUMBER
	call	DEinHL
	pop	de		; <-- lvl 1
	call	DEinHL
	ld	(HERE), hl
	jp	next
.notfound:
	ld	hl, .msg
	call	printstr
	jp	abort
.msg:
	.db	"word not found", 0

; ( -- c )
	.db "KEY"
	.fill 4
	.dw APOSI
	.db 0
KEY:
	.dw nativeWord
	call	stdioGetC
	ld	h, 0
	ld	l, a
	push	hl
	jp	next

	.db "WORD"
	.fill 3
	.dw KEY
	.db 0
WORD:
	.dw nativeWord
	call	readword
	jp	nz, abort
	push	hl
	jp	next

	.db "CREATE"
	.fill 1
	.dw WORD
	.db 0
CREATE:
	.dw nativeWord
	call	entryhead
	ld	de, cellWord
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	ld	(HERE), hl
	jp	next

	.db "HERE"
	.fill 3
	.dw CREATE
	.db 0
HERE_:	; Caution: conflicts with actual variable name
	.dw sysvarWord
	.dw HERE

	.db "CURRENT"
	.dw HERE_
	.db 0
CURRENT_:
	.dw sysvarWord
	.dw CURRENT

; ( n -- )
	.db "."
	.fill 6
	.dw CURRENT_
	.db 0
DOT:
	.dw nativeWord
	pop	de
	; We check PS explicitly because it doesn't look nice to spew gibberish
	; before aborting the stack underflow.
	call	chkPSRS
	call	pad
	call	fmtDecimalS
	call	printstr
	jp	next

; ( n a -- )
	.db "!"
	.fill 6
	.dw DOT
	.db 0
STORE:
	.dw nativeWord
	pop	iy
	pop	hl
	ld	(iy), l
	ld	(iy+1), h
	jp	next

; ( n a -- )
	.db "C!"
	.fill 5
	.dw STORE
	.db 0
CSTORE:
	.dw nativeWord
	pop	hl
	pop	de
	ld	(hl), e
	jp	next

; ( a -- n )
	.db "@"
	.fill 6
	.dw CSTORE
	.db 0
FETCH:
	.dw nativeWord
	pop	hl
	call	intoHL
	push	hl
	jp	next

; ( a -- c )
	.db "C@"
	.fill 5
	.dw FETCH
	.db 0
CFETCH:
	.dw nativeWord
	pop	hl
	ld	l, (hl)
	ld	h, 0
	push	hl
	jp	next

	.db "LIT@"
	.fill 3
	.dw CFETCH
	.db 0
LITFETCH:
	.dw nativeWord
	call	readLITTOS
	push	hl
	jp	next

; ( a b -- b a )
	.db "SWAP"
	.fill 3
	.dw LITFETCH
	.db 0
SWAP:
	.dw nativeWord
	pop	hl
	ex	(sp), hl
	push	hl
	jp	next

; ( a b c d -- c d a b )
	.db "2SWAP"
	.fill 2
	.dw SWAP
	.db 0
SWAP2:
	.dw nativeWord
	pop	de		; D
	pop	hl		; C
	pop	bc		; B

	ex	(sp), hl	; A in HL
	push	de		; D
	push	hl		; A
	push	bc		; B
	jp	next

; ( a -- a a )
	.db "DUP"
	.fill 4
	.dw SWAP2
	.db 0
DUP:
	.dw nativeWord
	pop	hl
	push	hl
	push	hl
	jp	next

; ( a b -- a b a b )
	.db "2DUP"
	.fill 3
	.dw DUP
	.db 0
DUP2:
	.dw nativeWord
	pop	hl	; B
	pop	de	; A
	push	de
	push	hl
	push	de
	push	hl
	jp	next

; ( a b -- a b a )
	.db "OVER"
	.fill 3
	.dw DUP2
	.db 0
OVER:
	.dw nativeWord
	pop	hl	; B
	pop	de	; A
	push	de
	push	hl
	push	de
	jp	next

; ( a b c d -- a b c d a b )
	.db "2OVER"
	.fill 2
	.dw OVER
	.db 0
OVER2:
	.dw nativeWord
	pop	hl	; D
	pop	de	; C
	pop	bc	; B
	pop	iy	; A
	push	iy	; A
	push	bc	; B
	push	de	; C
	push	hl	; D
	push	iy	; A
	push	bc	; B
	jp	next

	.db	">R"
	.fill	5
	.dw	OVER2
	.db	0
P2R:
	.dw	nativeWord
	pop	hl
	call	pushRS
	jp	next

	.db	"R>"
	.fill	5
	.dw	P2R
	.db	0
R2P:
	.dw	nativeWord
	call	popRS
	push	hl
	jp	next

	.db	"I"
	.fill	6
	.dw	R2P
	.db	0
I:
	.dw	nativeWord
	ld	l, (ix)
	ld	h, (ix+1)
	push	hl
	jp	next

	.db	"I'"
	.fill	5
	.dw	I
	.db	0
IPRIME:
	.dw	nativeWord
	ld	l, (ix-2)
	ld	h, (ix-1)
	push	hl
	jp	next

	.db	"J"
	.fill	6
	.dw	IPRIME
	.db	0
J:
	.dw	nativeWord
	ld	l, (ix-4)
	ld	h, (ix-3)
	push	hl
	jp	next

; ( a b -- c ) A + B
	.db "+"
	.fill 6
	.dw J
	.db 0
PLUS:
	.dw nativeWord
	pop	hl
	pop	de
	add	hl, de
	push	hl
	jp	next

; ( a b -- c ) A - B
	.db "-"
	.fill 6
	.dw PLUS
	.db 0
MINUS:
	.dw nativeWord
	pop	de		; B
	pop	hl		; A
	or	a		; reset carry
	sbc	hl, de
	push	hl
	jp	next

; ( a b -- c ) A * B
	.db "*"
	.fill 6
	.dw MINUS
	.db 0
MULT:
	.dw nativeWord
	pop	de
	pop	bc
	call	multDEBC
	push	hl
	jp	next

; ( a b -- c ) A / B
	.db "/"
	.fill 6
	.dw MULT
	.db 0
DIV:
	.dw nativeWord
	pop	de
	pop	hl
	call	divide
	push	bc
	jp	next

; ( a1 a2 -- b )
	.db "SCMP"
	.fill 3
	.dw DIV
	.db 0
SCMP:
	.dw nativeWord
	pop	de
	pop	hl
	call	strcmp
	call	flagsToBC
	push	bc
	jp	next

; ( n1 n2 -- f )
	.db "CMP"
	.fill 4
	.dw SCMP
	.db 0
CMP:
	.dw nativeWord
	pop	hl
	pop	de
	or	a	; clear carry
	sbc	hl, de
	call	flagsToBC
	push	bc
	jp	next

	.db	"SKIP?"
	.fill	2
	.dw	CMP
	.db	0
CSKIP:
	.dw	nativeWord
	pop	hl
	ld	a, h
	or	l
	jp	z, next		; False, do nothing.
	ld	hl, (IP)
	call	compSkip
	ld	(IP), hl
	jp	next

; This word's atom is followed by 1b *relative* offset (to the cell's addr) to
; where to branch to. For example, The branching cell of "IF THEN" would
; contain 3. Add this value to RS.
	.db	"(fbr)"
	.fill	2
	.dw	CSKIP
	.db	0
FBR:
	.dw	nativeWord
	push	de
	ld	hl, (IP)
	ld	a, (hl)
	call	addHL
	ld	(IP), hl
	pop	de
	jp	next

LATEST:
	.dw FBR

