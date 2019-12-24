; Whether A is a separator or end-of-string (null or ':')
isSepOrEnd:
	or	a
	ret	z
	cp	':'
	ret	z
	; continue to isSep

; Sets Z is A is ' ' or '\t' (whitespace)
isSep:
	cp	' '
	ret	z
	cp	0x09
	ret

; Expect at least one whitespace (0x20, 0x09) at (HL), and then advance HL
; until a non-whitespace character is met.
; HL is advanced to the first non-whitespace char.
; Sets Z on success, unset on failure.
; Failure is either not having a first whitespace or reaching the end of the
; string.
; Sets Z if we found a non-whitespace char, unset if we found the end of string.
rdSep:
	ld	a, (hl)
	call	isSep
	ret	nz	; failure
.loop:
	inc	hl
	ld	a, (hl)
	call	isSep
	jr	z, .loop
	call	isSepOrEnd
	jp	z, .fail	; unexpected EOL. fail
	cp	a	; ensure Z
	ret
.fail:
	; A is zero at this point
	inc	a	; unset Z
	ret

; Advance HL to the next separator or to the end of string.
toSepOrEnd:
	ld	a, (hl)
	call	isSepOrEnd
	ret	z
	inc	hl
	jr	toSepOrEnd

; Advance HL to the end of the line, that is, either a null terminating char
; or the ':'.
; Sets Z if we met a null char, unset if we met a ':'
toEnd:
	ld	a, (hl)
	or	a
	ret	z
	cp	':'
	jr	z, .havesep
	inc	hl
	call	skipQuoted
	jr	toEnd
.havesep:
	inc	a	; unset Z
	ret

; Read (HL) until the next separator and copy it in (DE)
; DE is preserved, but HL is advanced to the end of the read word.
rdWord:
	push	af
	push	de
.loop:
	ld	a, (hl)
	call	isSepOrEnd
	jr	z, .stop
	ld	(de), a
	inc	hl
	inc	de
	jr	.loop
.stop:
	xor	a
	ld	(de), a
	pop	de
	pop	af
	ret

; Read word from HL in SCRATCHPAD and then intepret that word as an expression.
; Put the result in IX.
; Z for success.
; TODO: put result in DE
rdExpr:
	ld	de, SCRATCHPAD
	call	rdWord
	push	hl
	ex	de, hl
	call	parseExprDE
	push	de \ pop ix
	pop	hl
	ret
