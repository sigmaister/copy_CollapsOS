; Return address of scratchpad in HL
pad:
	ld	hl, (HERE)
	ld	a, PADDING
	call	addHL
	ret

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
	ld	hl, 8		; prev field offset
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
	ld	a, 8
	call	strncmp
	ret	z		; found
	call	prev
	jr	nz, .inner
	; Z set? end of dict unset Z
	inc	a
	ret

; Compile word string at (HL) and write down its compiled version in IY,
; advancing IY to the byte next to the last written byte.
; Set Z on success, unset on failure.
compile:
	call	find
	ret	nz
	; DE is a word offset, we need a code link
	ld	hl, CODELINK_OFFSET
	add	hl, de
	ld	(iy), l
	inc	iy
	ld	(iy), h
	inc	iy
	xor	a	; set Z
	ret

compileExit:
	ld	hl, EXIT+CODELINK_OFFSET
	ld	(iy), l
	inc	iy
	ld	(iy), h
	inc	iy
	ret

