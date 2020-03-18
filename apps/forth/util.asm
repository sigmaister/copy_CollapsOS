; *** Collapse OS lib copy ***
; In the process of Forth-ifying Collapse OS, apps will be slowly rewritten to
; Forth and the concept of ASM libs will become obsolete. To facilitate this
; transition, I make, right now, a copy of the routines actually used by Forth's
; native core. This also has the effect of reducing binary size right now and
; give us an idea of Forth's compactness.
; These routines below are copy/paste from apps/lib.

; make Z the opposite of what it is now
toggleZ:
	jp	z, unsetZ
	cp	a
	ret

; Copy string from (HL) in (DE), that is, copy bytes until a null char is
; encountered. The null char is also copied.
; HL and DE point to the char right after the null char.
strcpyM:
	ld	a, (hl)
	ld	(de), a
	inc	hl
	inc	de
	or	a
	jr	nz, strcpyM
	ret

; Like strcpyM, but preserve HL and DE
strcpy:
	push	hl
	push	de
	call	strcpyM
	pop	de
	pop	hl
	ret

; Compares strings pointed to by HL and DE until one of them hits its null char.
; If equal, Z is set. If not equal, Z is reset. C is set if HL > DE
strcmp:
	push	hl
	push	de

.loop:
	ld	a, (de)
	cp	(hl)
	jr	nz, .end	; not equal? break early. NZ is carried out
				; to the caller
	or	a		; If our chars are null, stop the cmp
	inc	hl
	inc	de
	jr	nz, .loop	; Z is carried through

.end:
	pop	de
	pop	hl
	; Because we don't call anything else than CP that modify the Z flag,
	; our Z value will be that of the last cp (reset if we broke the loop
	; early, set otherwise)
	ret

; Given a string at (HL), move HL until it points to the end of that string.
strskip:
	push	bc
	ex	af, af'
	xor	a	; look for null char
	ld	b, a
	ld	c, a
	cpir	; advances HL regardless of comparison, so goes one too far
	dec	hl
	ex	af, af'
	pop	bc
	ret

; Borrowed from Tasty Basic by Dimitri Theulings (GPL).
; Divide HL by DE, placing the result in BC and the remainder in HL.
divide:
	push hl		; --> lvl 1
	ld l, h		; divide h by de
	ld h, 0
	call .dv1
	ld b, c		; save result in b
	ld a, l		; (remainder + l) / de
	pop hl		; <-- lvl 1
	ld h, a
.dv1:
	ld c, 0xff	; result in c
.dv2:
	inc c		; dumb routine
	call .subde	; divide using subtract and count
	jr nc, .dv2
	add hl, de
	ret
.subde:
	ld a, l
	sub e		; subtract de from hl
	ld l, a
	ld a, h
	sbc a, d
	ld h, a
	ret

; DE * BC -> DE (high) and HL (low)
multDEBC:
	ld	hl, 0
	ld	a, 0x10
.loop:
	add	hl, hl
	rl	e
	rl	d
	jr	nc, .noinc
	add	hl, bc
	jr	nc, .noinc
	inc	de
.noinc:
	dec a
	jr	nz, .loop
	ret

; Parse string at (HL) as a decimal value and return value in DE.
; Reads as many digits as it can and stop when:
; 1 - A non-digit character is read
; 2 - The number overflows from 16-bit
; HL is advanced to the character following the last successfully read char.
; Error conditions are:
; 1 - There wasn't at least one character that could be read.
; 2 - Overflow.
; Sets Z on success, unset on error.

parseDecimal:
	; First char is special: it has to succeed.
	ld	a, (hl)
	; Parse the decimal char at A and extract it's 0-9 numerical value. Put the
	; result in A.
	; On success, the carry flag is reset. On error, it is set.
	add	a, 0xff-'9'	; maps '0'-'9' onto 0xf6-0xff
	sub	0xff-9		; maps to 0-9 and carries if not a digit
	ret	c		; Error. If it's C, it's also going to be NZ
	; During this routine, we switch between HL and its shadow. On one side,
	; we have HL the string pointer, and on the other side, we have HL the
	; numerical result. We also use EXX to preserve BC, saving us a push.
	exx		; HL as a result
	ld	h, 0
	ld	l, a	; load first digit in without multiplying

.loop:
	exx		; HL as a string pointer
	inc hl
	ld a, (hl)
	exx		; HL as a numerical result

	; same as other above
	add	a, 0xff-'9'
	sub	0xff-9
	jr	c, .end

	ld	b, a	; we can now use a for overflow checking
	add	hl, hl	; x2
	sbc	a, a	; a=0 if no overflow, a=0xFF otherwise
	ld	d, h
	ld	e, l		; de is x2
	add	hl, hl	; x4
	rla
	add	hl, hl	; x8
	rla
	add	hl, de	; x10
	rla
	ld	d, a	; a is zero unless there's an overflow
	ld	e, b
	add	hl, de
	adc	a, a	; same as rla except affects Z
	; Did we oveflow?
	jr	z, .loop	; No? continue
	; error, NZ already set
	exx		; HL is now string pointer, restore BC
	; HL points to the char following the last success.
	ret

.end:
	push	hl	; --> lvl 1, result
	exx		; HL as a string pointer, restore BC
	pop	de	; <-- lvl 1, result
	cp	a	; ensure Z
	ret

; *** Forth-specific part ***
; Return address of scratchpad in HL
pad:
	ld	hl, (HERE)
	ld	a, PADDING
	jp	addHL

; Advance (INPUTPOS) until a non-whitespace is met. If needed,
; call fetchline.
; Set HL to newly set (INPUTPOS)
toword:
	ld	hl, (INPUTPOS)
	; skip leading whitespace
	dec	hl	; offset leading "inc hl"
.loop:
	inc	hl
	ld	a, (hl)
	or	a
	; When at EOL, fetch a new line directly
	jr	z, .empty
	cp	' '+1
	jr	c, .loop
	ret
.empty:
	call	fetchline
	jr	toword

; Read word from (INPUTPOS) and return, in HL, a null-terminated word.
; Advance (INPUTPOS) to the character following the whitespace ending the
; word.
; When we're at EOL, we call fetchline directly, so this call always returns
; a word.
readword:
	call	toword
	push	hl		; --> lvl 1. that's our result
.loop:
	inc	hl
	ld	a, (hl)
	; special case: is A null? If yes, we will *not* inc A so that we don't
	; go over the bounds of our input string.
	or	a
	jr	z, .noinc
	cp	' '+1
	jr	nc, .loop
	; we've just read a whitespace, HL is pointing to it. Let's transform
	; it into a null-termination, inc HL, then set (INPUTPOS).
	xor	a
	ld	(hl), a
	inc	hl
.noinc:
	ld	(INPUTPOS), hl
	pop	hl		; <-- lvl 1. our result
	ret	; Z set from XOR A

; Sets Z if (HL) == E and (HL+1) == D
HLPointsDE:
	ld	a, (hl)
	cp	e
	ret	nz		; no
	inc	hl
	ld	a, (hl)
	dec	hl
	cp	d		; Z has our answer
	ret


HLPointsNUMBER:
	push	de
	ld	de, NUMBER
	call	HLPointsDE
	pop	de
	ret

HLPointsLIT:
	push	de
	ld	de, LIT
	call	HLPointsDE
	pop	de
	ret

HLPointsBR:
	push	de
	ld	de, FBR
	call	HLPointsDE
	jr	z, .end
	ld	de, BBR
	call	HLPointsDE
.end:
	pop	de
	ret

; Skip the compword where HL is currently pointing. If it's a regular word,
; it's easy: we inc by 2. If it's a NUMBER, we inc by 4. If it's a LIT, we skip
; to after null-termination.
compSkip:
	call	HLPointsNUMBER
	jr	z, .isNum
	call	HLPointsBR
	jr	z, .isBranch
	call	HLPointsLIT
	jr	nz, .isWord
	; We have a literal
	inc	hl \ inc hl
	call	strskip
	inc	hl		; byte after word termination
	ret
.isNum:
	; skip by 4
	inc	hl
	; continue to isBranch
.isBranch:
	; skip by 3
	inc	hl
	; continue to isWord
.isWord:
	; skip by 2
	inc	hl \ inc hl
	ret

; Find the entry corresponding to word where (HL) points to and sets DE to
; point to that entry.
; Z if found, NZ if not.
find:
	push	hl
	push	bc
	ld	de, (CURRENT)
	ld	bc, CODELINK_OFFSET
.inner:
	; DE is a wordref, let's go to beginning of struct
	push	de		; --> lvl 1
	or	a		; clear carry
	ex	de, hl
	sbc	hl, bc
	ex	de, hl		; We're good, DE points to word name
	ld	a, NAMELEN
	call	strncmp
	pop	de		; <-- lvl 1, return to wordref
	jr	z, .end		; found
	call	.prev
	jr	nz, .inner
	; Z set? end of dict unset Z
	inc	a
.end:
	pop	bc
	pop	hl
	ret

; For DE being a wordref, move DE to the previous wordref.
; Z is set if DE point to 0 (no entry). NZ if not.
.prev:
	dec	de \ dec de \ dec de	; prev field
	call	intoDE
	; DE points to prev. Is it zero?
	xor	a
	or	d
	or	e
	; Z will be set if DE is zero
	ret

; Write compiled data from HL into IY, advancing IY at the same time.
wrCompHL:
	ld	(iy), l
	inc	iy
	ld	(iy), h
	inc	iy
	ret

; Spit name + prev in (HERE) and adjust (HERE) and (CURRENT)
; HL points to new (HERE)
entryhead:
	call	readword
	ld	de, (HERE)
	call	strcpy
	ex	de, hl		; (HERE) now in HL
	ld	de, (CURRENT)
	ld	a, NAMELEN
	call	addHL
	call	DEinHL
	; Set word flags: not IMMED, not UNWORD, so it's 0
	xor	a
	ld	(hl), a
	inc	hl
	ld	(CURRENT), hl
	ld	(HERE), hl
	ret

; Sets Z if wordref at HL is of the IMMEDIATE type
HLisIMMED:
	dec	hl
	bit	FLAG_IMMED, (hl)
	inc	hl
	; We need an invert flag. We want to Z to be set when flag is non-zero.
	jp	toggleZ

; Sets Z if wordref at HL is of the UNWORD type
HLisUNWORD:
	dec	hl
	bit	FLAG_UNWORD, (hl)
	inc	hl
	; We need an invert flag. We want to Z to be set when flag is non-zero.
	jp	toggleZ

; Sets Z if wordref at (HL) is of the IMMEDIATE type
HLPointsUNWORD:
	push	hl
	call	intoHL
	call	HLisUNWORD
	pop	hl
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

; Write DE in (HL), advancing HL by 2.
DEinHL:
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	ret

fetchline:
	call	printcrlf
	call	stdioReadLine
	ld	(INPUTPOS), hl
	ret
