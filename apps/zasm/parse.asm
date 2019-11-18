; Parse string in (HL) and return its numerical value whether its a number
; literal or a symbol. Returns value in IX.
; Sets Z if number or symbol is valid, unset otherwise.
parseNumberOrSymbol:
	call	parseLiteral
	ret	z
	; Not a number.
	; Is str a single char? If yes, maybe it's a special symbol.
	call	strIs1L
	jr	nz, .symbol	; nope
	ld	a, (hl)
	cp	'$'
	jr	z, .returnPC
	cp	'@'
	jr	nz, .symbol
	; last val
	ld	ix, (DIREC_LASTVAL)
	ret
.symbol:
	push	de		; --> lvl 1
	call	symFindVal	; --> DE
	jr	nz, .notfound
	; value in DE. We need it in IX
	push	de \ pop ix
	pop	de		; <-- lvl 1
	cp	a		; ensure Z
	ret
.notfound:
	pop	de		; <-- lvl 1
	; If not found, check if we're in first pass. If we are, it doesn't
	; matter that we didn't find our symbol. Return success anyhow.
	; Otherwise return error. Z is already unset, so in fact, this is the
	; same as jumping to zasmIsFirstPass
	; however, before we do, load IX with zero. Returning dummy non-zero
	; values can have weird consequence (such as false overflow errors).
	ld	ix, 0
	jp	zasmIsFirstPass

.returnPC:
	push	hl
	call	zasmGetPC
	push	hl \ pop ix
	pop	hl
	ret
