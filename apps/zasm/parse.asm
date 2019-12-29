; Parse string in (HL) and return its numerical value whether its a number
; literal or a symbol. Returns value in DE.
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
	ld	de, (DIREC_LASTVAL)
	ret
.symbol:
	call	symFindVal	; --> DE
	jr	nz, .notfound
	ret
.notfound:
	; If not found, check if we're in first pass. If we are, it doesn't
	; matter that we didn't find our symbol. Return success anyhow.
	; Otherwise return error. Z is already unset, so in fact, this is the
	; same as jumping to zasmIsFirstPass
	; however, before we do, load DE with zero. Returning dummy non-zero
	; values can have weird consequence (such as false overflow errors).
	ld	de, 0
	jp	zasmIsFirstPass

.returnPC:
	push	hl
	call	zasmGetPC
	ex	de, hl	; result in DE
	pop	hl
	ret
