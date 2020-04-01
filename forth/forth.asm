; Collapse OS Forth's boot binary

; *** Const ***
; Base of the Return Stack
.equ	RS_ADDR		0xf000
; Buffer where WORD copies its read word to.
.equ	WORD_BUFSIZE		0x20
; Allocated space for sysvars (see comment above SYSVCNT)
.equ	SYSV_BUFSIZE		0x10

; *** Variables ***
.equ	INITIAL_SP	RAMSTART
; wordref of the last entry of the dict.
.equ	CURRENT		@+2
; Pointer to the next free byte in dict.
.equ	HERE		@+2
; Interpreter pointer. See Execution model comment below.
.equ	IP		@+2
; Global flags
; Bit 0: whether the interpreter is executing a word (as opposed to parsing)
.equ	FLAGS		@+2
; Pointer to the system's number parsing function. It points to then entry that
; had the "(parse)" name at startup. During stage0, it's out builtin PARSE,
; but at stage1, it becomes "(parse)" from core.fs. It can also be changed at
; runtime.
.equ	PARSEPTR	@+2
; Pointer to the word executed by "C<". During stage0, this points to KEY.
; However, KEY ain't very interactive. This is why we implement a readline
; interface in Forth, which we plug in during init. If "(c<)" exists in the
; dict, CINPTR is set to it. Otherwise, we set KEY
.equ	CINPTR		@+2
.equ	WORDBUF		@+2
; Sys Vars are variables with their value living in the system RAM segment. We
; need this mechanisms for core Forth source needing variables. Because core
; Forth source is pre-compiled, it needs to be able to live in ROM, which means
; that we can't compile a regular variable in it. SYSVNXT points to the next
; free space in SYSVBUF. Then, at the word level, it's a regular sysvarWord.
.equ	SYSVNXT		@+WORD_BUFSIZE
.equ	RAMEND		@+SYSV_BUFSIZE+2

; (HERE) usually starts at RAMEND, but in certain situations, such as in stage0,
; (HERE) will begin at a strategic place.
.equ	HERE_INITIAL	RAMEND

; *** Stable ABI ***
; Those jumps below are supposed to stay at these offsets, always. If they
; change bootstrap binaries have to be adjusted because they rely on them.
; Those entries are referenced directly by their offset in Forth code with a
; comment indicating what that number refers to.
;
; We're at 0 here
	jp	forthMain
; 3
	jp	find
	nop \ nop	; unused
	nop \ nop \ nop	; unused
; 11
	jp	cellWord
	jp	compiledWord
	jp	pushRS
	jp	popRS
; 23
	jp	(iy)	; nativeWord. why use a jump when the real deal is
	nop		; more compact?
	jp	next
	jp	chkPS
; 32
	.dw	numberWord
	.dw	litWord
	.dw	INITIAL_SP
	.dw	WORDBUF
	jp	flagsToBC
	jp	doesWord
; 46
	.dw	RS_ADDR
	.dw	CINPTR
	.dw	SYSVNXT
	.dw	FLAGS
; 54
	.dw	PARSEPTR
	.dw	HERE
	.dw	CURRENT

; *** Boot dict ***
; There are only 5 words in the boot dict, but these words' offset need to be
; stable, so they're part of the "stable ABI"

; Pop previous IP from Return stack and execute it.
; ( R:I -- )
	.db	"EXIT"
	.dw	0
	.db	4
EXIT:
	.dw	23
	call	popRS
	ld	(IP), hl
	jp	next

.fill 3

	.db	"(br)"
	.dw	$-EXIT
	.db	4
BR:
	.dw	23
	ld	hl, (IP)
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	dec	hl
	add	hl, de
	ld	(IP), hl
	jp	next

	.db	"(?br)"
	.dw	$-BR
	.db	5
CBR:
	.dw	23
	pop	hl
	call	chkPS
	ld	a, h
	or	l
	jr	z, BR+2		; False, branch
	; True, skip next 2 bytes and don't branch
	ld	hl, (IP)
	inc	hl
	inc	hl
	ld	(IP), hl
	jp	next

	.db "EXECUTE"
	.dw $-CBR
	.db 7
EXECUTE:
	.dw 23
	pop	iy	; is a wordref
	call	chkPS
	ld	l, (iy)
	ld	h, (iy+1)
	; HL points to code pointer
	inc	iy
	inc	iy
	; IY points to PFA
	jp	(hl)	; go!

; Offset: 00a1
.out $
; *** End of stable ABI ***

forthMain:
	; STACK OVERFLOW PROTECTION:
	; To avoid having to check for stack underflow after each pop operation
	; (which can end up being prohibitive in terms of costs), we give
	; ourselves a nice 6 bytes buffer. 6 bytes because we seldom have words
	; requiring more than 3 items from the stack. Then, at each "exit" call
	; we check for stack underflow.
	ld	sp, 0xfffa
	ld	(INITIAL_SP), sp
	ld	ix, RS_ADDR
	; LATEST is a label to the latest entry of the dict. This can be
	; overridden if a binary dict has been grafted to the end of this
	; binary
	ld	hl, LATEST
	ld	(CURRENT), hl
	ld	hl, HERE_INITIAL
	ld	(HERE), hl
	ld	hl, .bootName
	call	find
	push	de
	jp	EXECUTE+2

.bootName:
	.db	"BOOT", 0

; Find the entry corresponding to word where (HL) points to and sets DE to
; point to that entry.
; Z if found, NZ if not.
find:
	push	bc
	push	hl
	; First, figure out string len
	ld	bc, 0
	xor	a
	cpir
	; C has our length, negative, -1
	ld	a, c
	neg
	dec	a
	; special case. zero len? we never find anything.
	jr	z, .fail
	ld	c, a		; C holds our length
	; Let's do something weird: We'll hold HL by the *tail*. Because of our
	; dict structure and because we know our lengths, it's easier to
	; compare starting from the end. Currently, after CPIR, HL points to
	; char after null. Let's adjust
	; Because the compare loop pre-decrements, instead of DECing HL twice,
	; we DEC it once.
	dec	hl
	ld	de, (CURRENT)
.inner:
	; DE is a wordref. First step, do our len correspond?
	push	hl		; --> lvl 1
	push	de		; --> lvl 2
	dec	de
	ld	a, (de)
	and	0x7f		; remove IMMEDIATE flag
	cp	c
	jr	nz, .loopend
	; match, let's compare the string then
	dec	de \ dec de	; skip prev field. One less because we
				; pre-decrement
	ld	b, c		; loop C times
.loop:
	; pre-decrement for easier Z matching
	dec	de
	dec	hl
	ld	a, (de)
	cp	(hl)
	jr	nz, .loopend
	djnz	.loop
.loopend:
	; At this point, Z is set if we have a match. In all cases, we want
	; to pop HL and DE
	pop	de		; <-- lvl 2
	pop	hl		; <-- lvl 1
	jr	z, .end		; match? we're done!
	; no match, go to prev and continue
	push	hl			; --> lvl 1
	dec	de \ dec de \ dec de	; prev field
	push	de			; --> lvl 2
	ex 	de, hl
	ld 	e, (hl)
	inc 	hl
	ld 	d, (hl)
	; DE contains prev offset
	pop	hl			; <-- lvl 2
	; HL is prev field's addr
	; Is offset zero?
	ld	a, d
	or	e
	jr	z, .noprev		; no prev entry
	; get absolute addr from offset
	; carry cleared from "or e"
	sbc	hl, de
	ex	de, hl			; result in DE
.noprev:
	pop	hl			; <-- lvl 1
	jr	nz, .inner		; try to match again
	; Z set? end of dict unset Z
.fail:
	xor	a
	inc	a
.end:
	pop	hl
	pop	bc
	ret

; Checks flags Z and S and sets BC to 0 if Z, 1 if C and -1 otherwise
flagsToBC:
	ld	bc, 0
	ret	z	; equal
	inc	bc
	ret	m	; >
	; <
	dec	bc
	dec	bc
	ret

; Push value HL to RS
pushRS:
	inc	ix
	inc	ix
	ld	(ix), l
	ld	(ix+1), h
	ret

; Pop RS' TOS to HL
popRS:
	ld	l, (ix)
	ld	h, (ix+1)
	dec ix
	dec ix
	ret

; Verifies that SP and RS are within bounds. If it's not, call ABORT
chkRS:
	push	ix \ pop hl
	push	de		; --> lvl 1
	ld	de, RS_ADDR
	or	a		; clear carry
	sbc	hl, de
	pop	de		; <-- lvl 1
	jp	c, abortUnderflow
	ret

chkPS:
	push	hl
	ld	hl, (INITIAL_SP)
	; We have the return address for this very call on the stack and
	; protected registers. Let's compensate
	dec	hl \ dec hl
	dec	hl \ dec hl
	or	a		; clear carry
	sbc	hl, sp
	pop	hl
	ret	nc		; (INITIAL_SP) >= SP? good
	jp	abortUnderflow

abortUnderflow:
	ld	hl, .name
	call	find
	push	de
	jp	EXECUTE+2
.name:
	.db "(uflw)", 0

; This routine is jumped to at the end of every word. In it, we jump to current
; IP, but we also take care of increasing it my 2 before jumping
next:
	; Before we continue: are stacks within bounds?
	call	chkPS
	call	chkRS
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


; *** Word routines ***

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

; Similarly to numberWord, this is not a real word, but a string literal.
; Instead of being followed by a 2 bytes number, it's followed by a
; null-terminated string. When called, puts the string's address on PS
litWord:
	ld	hl, (IP)
	push	hl
	; Skip to null char
	xor	a	; look for null char
	ld	b, a
	ld	c, a
	cpir
	; CPIR advances HL regardless of comparison, so goes one char after
	; NULL. This is good, because that's what we want...
	ld	(IP), hl
	jp	next

; *** Dict hook ***
; This dummy dictionary entry serves two purposes:
; 1. Allow binary grafting. Because each binary dict always end with a dummy
;    entry, we always have a predictable prev offset for the grafter's first
;    entry.
; 2. Tell icore's "_c" routine where the boot binary ends. See comment there.

	.db	"_bend"
	.dw	$-EXECUTE
	.db	5

; Offset: 01c3
.out $
