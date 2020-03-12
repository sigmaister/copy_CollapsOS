; Sets Z is A is ' ' or '\t' (whitespace)
isWS:
	cp	' '
	ret	z
	cp	0x09
	ret

; Advance HL to next WS.
; Set Z if WS found, unset if end-of-string.
toWS:
	ld	a, (hl)
	call	isWS
	ret	z
	cp	0x01	; if a is null, carries and unsets z
	ret	c
	inc	hl
	jr	toWS

; Consume following whitespaces in HL until a non-WS is hit.
; Set Z if non-WS found, unset if end-of-string.
rdWS:
	ld	a, (hl)
	cp	0x01	; if a is null, carries and unsets z
	ret	c
	call	isWS
	jr	nz, .ok
	inc	hl
	jr	rdWS
.ok:
	cp	a	; ensure Z
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

; Returns length of string at (HL) in A.
; Doesn't include null termination.
strlen:
	push	bc
	xor	a	; look for null char
	ld	b, a
	ld	c, a
	cpir		; advances HL to the char after the null
.found:
	; How many char do we have? We have strlen=(NEG BC)-1, since BC started
	; at 0 and decreased at each CPIR loop. In this routine,
	; we stay in the 8-bit realm, so C only.
	add 	hl, bc
	sub	c
	dec	a
	pop	bc
	ret

; make Z the opposite of what it is now
toggleZ:
	jp	z, unsetZ
	cp	a
	ret

