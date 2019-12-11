; *** Requirements ***
; stdioPutC
; divide
;

; Same as fmtDecimal, but DE is considered a signed number
fmtDecimalS:
	bit	7, d
	jr	z, fmtDecimal	; unset, not negative
	; Invert DE. spit '-', unset bit, then call fmtDecimal
	push	de
	ld	a, '-'
	ld	(hl), a
	inc	hl
	ld	a, d
	cpl
	ld	d, a
	ld	a, e
	cpl
	ld	e, a
	inc	de
	call	fmtDecimal
	dec	hl
	pop	de
	ret

; Format the number in DE into the string at (HL) in a decimal form.
; Null-terminated. DE is considered an unsigned number.
fmtDecimal:
	push	ix
	push	hl
	push	de
	push	af

	push	hl \ pop ix
	ex	de, hl	; orig number now in HL
	ld	e, 0
.loop1:
	call	.div10
	push	hl	; push remainder. --> lvl E
	inc	e
	ld	a, b		; result 0?
	or	c
	push	bc \ pop hl
	jr	nz, .loop1	; not zero, continue
	; We now have C digits to print in the stack.
	; Spit them!
	push	ix \ pop hl	; restore orig HL.
	ld	b, e
.loop2:
	pop	de	; <-- lvl E
	ld	a, '0'
	add	a, e
	ld	(hl), a
	inc	hl
	djnz	.loop2

	; null terminate
	xor	a
	ld	(hl), a
	pop	af
	pop	de
	pop	hl
	pop	ix
	ret
.div10:
	push	de
	ld	de, 0x000a
	call	divide
	pop	de
	ret

; Format the lower nibble of A into a hex char and stores the result in A.
fmtHex:
	; The idea here is that there's 7 characters between '9' and 'A'
	; in the ASCII table, and so we add 7 if the digit is >9.
	; daa is designed for using Binary Coded Decimal format, where each
	; nibble represents a single base 10 digit. If a nibble has a value >9,
	; it adds 6 to that nibble, carrying to the next nibble and bringing the
	; value back between 0-9. This gives us 6 of that 7 we needed to add, so
	; then we just condtionally set the carry and add that carry, along with
	; a number that maps 0 to '0'. We also need the upper nibble to be a
	; set value, and have the N, C and H flags clear.
	or 	0xf0
	daa	; now a =0x50 + the original value + 0x06 if >= 0xfa
	add 	a, 0xa0	; cause a carry for the values that were >=0x0a
	adc 	a, 0x40
	ret

; Print the hex char in A as a pair of hex digits.
printHex:
	push	af

	; let's start with the leftmost char
	rra \ rra \ rra \ rra
	call	fmtHex
	call	stdioPutC

	; and now with the rightmost
	pop	af \ push af
	call	fmtHex
	call	stdioPutC

	pop	af
	ret

; Print the hex pair in HL
printHexPair:
	push	af
	ld	a, h
	call	printHex
	ld	a, l
	call	printHex
	pop	af
	ret
