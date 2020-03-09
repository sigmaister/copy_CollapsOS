; Return address of scratchpad in HL
pad:
	ld	hl, (HERE)
	ld	a, PADDING
	jp	addHL

; Read word from (INPUTPOS) and return, in HL, a null-terminated word.
; Advance (INPUTPOS) to the character following the whitespace ending the
; word.
; Z set of word was read, unset if end of line.
readword:
	ld	hl, (INPUTPOS)
	; skip leading whitespace
	dec	hl	; offset leading "inc hl"
.loop1:
	inc	hl
	ld	a, (hl)
	or	a
	jr	z, .empty
	cp	' '+1
	jr	c, .loop1
	push	hl		; --> lvl 1. that's our result
.loop2:
	inc	hl
	ld	a, (hl)
	; special case: is A null? If yes, we will *not* inc A so that we don't
	; go over the bounds of our input string.
	or	a
	jr	z, .noinc
	cp	' '+1
	jr	nc, .loop2
	; we've just read a whitespace, HL is pointing to it. Let's transform
	; it into a null-termination, inc HL, then set (INPUTPOS).
	xor	a
	ld	(hl), a
	inc	hl
.noinc:
	ld	(INPUTPOS), hl
	pop	hl		; <-- lvl 1. our result
	ret	; Z set from XOR A
.empty:
	ld	(hl), a
	inc	a	; unset Z
	ret

RSIsDE:
	push	hl
	ld	l, (ix)
	ld	h, (ix+1)
	ld	a, (hl)
	cp	e
	jr	nz, .end	; no
	inc	hl
	ld	a, (hl)
	cp	d		; Z has our answer
.end:
	pop	hl
	ret


; Is RS' TOS pointing to a NUMBER word?
; Z if yes, NZ if no.
RSIsNUMBER:
	push	de
	ld	de, NUMBER
	call	RSIsDE
	pop	de
	ret

; Is RS' TOS pointing to a LIT word?
; Z if yes, NZ if no.
RSIsLIT:
	push	de
	ld	de, LIT
	call	RSIsDE
	pop	de
	ret

; Is RS' TOS pointing to EXIT?
; Z if yes, NZ if no.
RSIsEXIT:
	push	de
	ld	de, EXIT+CODELINK_OFFSET
	call	RSIsDE
	pop	de
	ret

; Skip the compword where RS' TOS is currently pointing. If it's a regular word,
; it's easy: we inc by 2. If it's a NUMBER, we inc by 4. If it's a LIT, we skip
; to after null-termination.
compSkip:
	push	hl
	ld	l, (ix)
	ld	h, (ix+1)
	; At the minimum, we skip by 2
	inc	hl \ inc hl
	call	RSIsNUMBER
	jr	z, .isNum
	call	RSIsLIT
	jr	nz, .end	; A word
	; We have a literal
	call	strskip
	inc	hl		; byte after word termination
	jr	.end
.isNum:
	; skip by 4
	inc	hl \ inc hl
.end:
	; HL is good, write it to RS
	ld	(ix), l
	ld	(ix+1), h
	pop	hl
	ret

; Checks RS' TOS and, if it points to a string literal (LIT), makes HL point
; to it and advance IP to byte following null-termination.
; If it doesn't, things get interesting: If it's a word reference, then it's
; not an invalid literal. For example, one could want to redefine an existing
; word. So in that case, we'll copy the word's name on the pad (it might not be
; null-terminated) and set HL to point to it.
; How do we know that our reference is a word reference (it could be, for
; example, a NUMBER reference)? We check that its address is more than QUIT, the
; second word in our dict. We don't accept EXIT because it's the termination
; word. Yeah, it means that ";" can't be overridden...
; If name can't be read, we abort
readCompWord:
	; In all cases, we want RS' TOS in HL. Let's get it now.
	ld	l, (ix)
	ld	h, (ix+1)
	call	RSIsLIT
	jr	nz, .notLIT
	; RS TOS is a LIT, make HL point to string, then skip this RS compword.
	inc	hl \ inc hl	; HL now points to string itself
	jr	compSkip
.notLIT:
	; Alright, not a literal, but is it a word? If it's not a number, then
	; it's a word.
	call	RSIsNUMBER
	jr	z, .notWord
	; Not a number, then it's a word. Copy word to pad and point to it.
	call	intoHL
	or	a		; clear carry
	ld	de, CODELINK_OFFSET
	sbc	hl, de
	; That's our return value
	push	hl		; --> lvl 1
	; HL now points to word offset, let'd copy it to pad
	ex	de, hl
	call	pad
	ex	de, hl
	ld	bc, NAMELEN
	ldir
	; null-terminate
	xor	a
	ld	(de), a
	call	compSkip
	pop	hl		; <-- lvl 1
	ret
.notWord:
	ld	hl, .msg
	call	printstr
	jp	abort
.msg:
	.db "word expected", 0

; For DE pointing to a dict entry, set DE to point to the previous entry.
; Z is set if DE point to 0 (no entry). NZ if not.
prev:
	push	hl		; --> lvl 1
	ld	hl, NAMELEN	; prev field offset
	add	hl, de
	ex	de, hl
	pop	hl		; <-- lvl 1
	call	intoDE
	; DE points to prev. Is it zero?
	xor	a
	or	d
	or	e
	; Z will be set if DE is zero
	ret

; Find the entry corresponding to word where (HL) points to and sets DE to
; point to that entry.
; Z if found, NZ if not.
find:
	ld	de, (CURRENT)
.inner:
	ld	a, NAMELEN
	call	strncmp
	ret	z		; found
	call	prev
	jr	nz, .inner
	; Z set? end of dict unset Z
	inc	a
	ret

; Write compiled data from HL into IY, advancing IY at the same time.
wrCompHL:
	ld	(iy), l
	inc	iy
	ld	(iy), h
	inc	iy
	ret

; Compile word string at (HL) and write down its compiled version in IY,
; advancing IY to the byte next to the last written byte.
compile:
	call	find
	jr	nz, .maybeNum
	; DE is a word offset, we need a code link
	ld	hl, CODELINK_OFFSET
	add	hl, de
	xor	a	; set Z
	jr	wrCompHL
.maybeNum:
	push	hl		; --> lvl 1. save string addr
	call	parseLiteral
	jr	nz, .undef
	pop	hl		; <-- lvl 1
	; a valid number!
	ld	hl, NUMBER
	call	wrCompHL
	ex	de, hl		; number in HL
	jr	wrCompHL
.undef:
	; When encountering an undefined word during compilation, we spit a
	; reference to litWord, followed by the null-terminated word.
	; This way, if a preceding word expect a string literal, it will read it
	; by calling readCompWord, and if it doesn't, the routine will be
	; called, triggering an abort.
	ld	hl, LIT
	call	wrCompHL
	pop	hl		; <-- lvl 1. recall string addr
.writeLit:
	ld	a, (hl)
	ld	(iy), a
	inc	hl
	inc	iy
	or	a
	jr	nz, .writeLit
	ret


; Spit name + prev in (HERE) and adjust (HERE) and (CURRENT)
; HL points to new (HERE)
entryhead:
	call	readCompWord
	call	printstr
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
	ld	(HERE), hl
	xor	a		; set Z
	ret
