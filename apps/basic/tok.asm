; Expect at least one whitespace (0x20, 0x09) at (HL), and then advance HL
; until a non-whitespace character is met.
; HL is advanced to the first non-whitespace char.
; Sets Z on success, unset on failure.
; Failure is either not having a first whitespace or reaching the end of the
; string.
; Sets Z if we found a non-whitespace char, unset if we found the end of string.
rdWS:
	ld	a, (hl)
	call	isSep
	ret	nz	; failure
.loop:
	inc	hl
	ld	a, (hl)
	call	isSep
	jr	z, .loop
	or	a	; cp 0
	jp	z, .fail
	cp	a	; ensure Z
	ret
.fail:
	; A is zero at this point
	inc	a	; unset Z
	ret

; Find the first whitespace in (HL) and returns its index in A
; Sets Z if whitespace is found, unset if end of string was found.
; In the case where no whitespace was found, A returns the length of the string.
fnWSIdx:
	push	hl
	push	bc
	ld	b, 0
.loop:
	ld	a, (hl)
	call	isSep
	jr	z, .found
	or	a
	jr	z, .eos
	inc	hl
	inc	b
	jr	.loop
.eos:
	inc	a	; unset Z
.found:			; Z already set from isSep
	ld	a, b
	pop	bc
	pop	hl
	ret
