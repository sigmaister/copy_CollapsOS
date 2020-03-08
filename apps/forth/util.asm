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
; Set Z on success, unset on failure.
compile:
	call	find
	jr	nz, .maybeNum
	ret	nz
	; DE is a word offset, we need a code link
	ld	hl, CODELINK_OFFSET
	add	hl, de
	xor	a	; set Z
	jr	wrCompHL
.maybeNum:
	call	parseLiteral
	ret	nz
	; a valid number!
	ld	hl, NUMBER
	call	wrCompHL
	ex	de, hl		; number in HL
	jr	wrCompHL
	ret	z
	; unknown name
	ld	hl, .msg
	call	printstr
	jp	abort
.msg:
	.db "unknown name", 0

; Spit name + prev in (HERE) and adjust (HERE) and (CURRENT)
; HL points to new (HERE)
; Set Z if name could be read, NZ if not
entryhead:
	call	readword
	ret	nz
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
