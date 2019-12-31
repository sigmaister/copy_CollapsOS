; Parse string in (HL) and return its numerical value whether its a number
; literal or a symbol. Returns value in DE.
; HL is advanced to the character following the last successfully read char.
; Sets Z if number or symbol is valid, unset otherwise.
parseNumberOrSymbol:
	call	isLiteralPrefix
	jp	z, parseLiteral
	; Not a number. try symbol
	ld	a, (hl)
	cp	'$'
	jr	z, .PC
	cp	'@'
	jr	z, .lastVal
	call	symParse
	ret	nz
	; HL at end of symbol name, DE at tmp null-terminated symname.
	push	hl		; --> lvl 1
	ex	de, hl
	call	symFindVal	; --> DE
	pop	hl		; <-- lvl 1
	ret	z
	; not found
	; When not found, check if we're in first pass. If we are, it doesn't
	; matter that we didn't find our symbol. Return success anyhow.
	; Otherwise return error. Z is already unset, so in fact, this is the
	; same as jumping to zasmIsFirstPass
	; however, before we do, load DE with zero. Returning dummy non-zero
	; values can have weird consequence (such as false overflow errors).
	ld	de, 0
	jp	zasmIsFirstPass

.PC:
	ex	de, hl
	call	zasmGetPC	; --> HL
	ex	de, hl	; result in DE
	inc	hl	; char after last read
	; Z already set from cp '$'
	ret

.lastVal:
	; last val
	ld	de, (DIREC_LASTVAL)
	inc	hl	; char after last read
	; Z already set from cp '@'
	ret
