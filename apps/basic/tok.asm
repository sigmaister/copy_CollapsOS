; Sets Z is A is ' ' or '\t' (whitespace), or ',' (arg sep)
isSep:
	cp	' '
	ret	z
	cp	0x09
	ret	z
	cp	','
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

; Advance HL to the next separator or to the end of string.
toSep:
	ld	a, (hl)
	call	isSep
	ret	z
	inc	hl
	jr	toSep

; Read (HL) until the next separator and copy it in (DE)
; DE is preserved, but HL is advanced to the end of the read word.
rdWord:
	push	af
	push	de
.loop:
	ld	a, (hl)
	call	isSep
	jr	z, .stop
	or	a
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
rdExpr:
	ld	de, SCRATCHPAD
	call	rdWord
	push	hl
	ex	de, hl
	call	parseExpr
	pop	hl
	ret
