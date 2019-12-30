; *** Requirements ***
; lib/util
; *** Code ***

; Parse the hex char at A and extract it's 0-15 numerical value. Put the result
; in A.
;
; On success, the carry flag is reset. On error, it is set.
parseHex:
	; First, let's see if we have an easy 0-9 case

	add 	a, 0xc6	; maps '0'-'9' onto 0xf6-0xff
	sub 	0xf6	; maps to 0-9 and carries if not a digit
	ret	nc

	and 	0xdf		; converts lowercase to uppercase
	add	a, 0xe9		; map 0x11-x017 onto 0xFA - 0xFF
	sub 	0xfa		; map onto 0-6
	ret 	c
	; we have an A-F digit
	add	a, 10		; C is clear, map back to 0xA-0xF
	ret


; Parse the decimal char at A and extract it's 0-9 numerical value. Put the
; result in A.
;
; On success, the carry flag is reset. On error, it is set.
; Also, zero flag set if '0'
; parseDecimalDigit has been replaced with the following code inline:
;	add	a, 0xff-'9'	; maps '0'-'9' onto 0xf6-0xff
;	sub	0xff-9		; maps to 0-9 and carries if not a digit

; Parse string at (HL) as a decimal value and return value in DE under the
; same conditions as parseLiteral.
; Sets Z on success, unset on error.
; To parse successfully, all characters following HL must be digits and those
; digits must form a number that fits in 16 bits. To end the number, both \0
; and whitespaces (0x20 and 0x09) are accepted. There must be at least one
; digit in the string.

parseDecimal:
	push 	hl		; --> lvl 1

	ld	a, (hl)
	add	a, 0xff-'9'	; maps '0'-'9' onto 0xf6-0xff
	sub	0xff-9		; maps to 0-9 and carries if not a digit
	jr	c, .error	; not a digit on first char? error
	exx		; preserve bc, hl, de
	ld	h, 0
	ld	l, a	; load first digit in without multiplying
	ld	b, 3	; Carries can only occur for decimals >=5 in length

.loop:
	exx
	inc hl
	ld a, (hl)
	exx

	; inline parseDecimalDigit
	add	a, 0xff-'9'	; maps '0'-'9' onto 0xf6-0xff
	sub	0xff-9		; maps to 0-9 and carries if not a digit
	jr	c, .end

	add	hl, hl	; x2
	ld	d, h
	ld	e, l		; de is x2
	add	hl, hl	; x4
	add	hl, hl	; x8
	add	hl, de	; x10
	ld	d, 0
	ld	e, a
	add	hl, de
	jr	c, .end	; if hl was 0x1999, it may carry here
	djnz	.loop


	inc 	b	; so loop only executes once more
	; only numbers >0x1999 can carry when multiplied by 10.
	ld	de, 0xE666
	ex	de, hl
	add	hl, de
	ex	de, hl
	jr	nc, .loop	; if it doesn't carry, it's small enough

	exx
	inc 	hl
	ld 	a, (hl)
	exx
	add 	a, 0xd0	; the next line expects a null to be mapped to 0xd0
.end:
	; Because of the add and sub in parseDecimalDigit, null is mapped
	; to 0x00+(0xff-'9')-(0xff-9)=-0x30=0xd0
	sub 	0xd0	; if a is null, set Z
			; a is checked for null before any errors
	push	hl	; --> lvl 2, result
	exx		; restore original bc
	pop	de	; <-- lvl 2, result
	pop	hl	; <-- lvl 1, orig
	ret	z
	; A is not 0? Ok, but if it's a space, we're happy too.
	jp	isWS
.error:
	pop	hl	; <-- lvl 1, orig
	jp	unsetZ

; Parse string at (HL) as a hexadecimal value without the "0x" prefix and
; return value in DE.
; HL is advanced to the character following the last successfully read char.
; Sets Z on success.
parseHexadecimal:
	ld	a, (hl)
	call	parseHex
	jp	c, unsetZ	; we need at least one char
	push	bc
	ld	de, 0
	ld	b, 0
.loop:
	; we push to B to verify overflow
	rl	e \ rl d \ rl b
	rl	e \ rl d \ rl b
	rl	e \ rl d \ rl b
	rl	e \ rl d \ rl b
	or	e
	ld	e, a
	; did we overflow?
	ld	a, b
	or	a
	jr	nz, .end	; overflow, NZ already set
	; next char
	inc	hl
	ld	a, (hl)
	call	parseHex
	jr	nc, .loop
	cp	a		; ensure Z
.end:
	pop	bc
	ret

; Parse string at (HL) as a binary value (010101) without the "0b" prefix and
; return value in E. D is always zero.
; Sets Z on success.
parseBinaryLiteral:
	push	bc
	push	hl
	call	strlen
	or	a
	jr	z, .error	; empty, error
	cp	9
	jr	nc, .error	; >= 9, too long
	; We have a string of 8 or less chars. What we'll do is that for each
	; char, we rotate left and set the LSB according to whether we have '0'
	; or '1'. Error out on anything else. C is our stored result.
	ld	b, a		; we loop for "strlen" times
	ld	c, 0		; our stored result
.loop:
	rlc	c
	ld	a, (hl)
	inc	hl
	cp	'0'
	jr	z, .nobit	; no bit to set
	cp	'1'
	jr	nz, .error	; not 0 or 1
	; We have a bit to set
	inc	c
.nobit:
	djnz	.loop
	ld	e, c
	cp	a		; ensure Z
	jr	.end
.error:
	call	unsetZ
.end:
	pop	hl
	pop	bc
	ret

; Parses the string at (HL) and returns the 16-bit value in DE. The string
; can be a decimal literal (1234), a hexadecimal literal (0x1234) or a char
; literal ('X').
;
; As soon as the number doesn't fit 16-bit any more, parsing stops and the
; number is invalid. If the number is valid, Z is set, otherwise, unset.
parseLiteral:
	ld	de, 0		; pre-fill
	ld	a, (hl)
	cp	0x27		; apostrophe
	jr	z, .char
	cp	'0'
	jr	z, .hexOrBin
	jp	parseDecimal

; Parse string at (HL) and, if it is a char literal, sets Z and return
; corresponding value in E. D is always zero.
;
; A valid char literal starts with ', ends with ' and has one character in the
; middle. No escape sequence are accepted, but ''' will return the apostrophe
; character.
.char:
	push	hl
	inc	hl
	inc	hl
	cp	(hl)
	jr	nz, .charEnd	; not ending with an apostrophe
	inc	hl
	ld	a, (hl)
	or	a		; cp 0
	jr	nz, .charEnd	; string has to end there
	; Valid char, good
	dec	hl
	dec	hl
	ld	e, (hl)
	cp	a		; ensure Z
.charEnd:
	pop	hl
	ret

.hexOrBin:
	inc	hl
	ld	a, (hl)
	inc	hl		; already place it for hex or bin
	cp	'x'
	jr	z, .hex
	cp	'b'
	jr	z, .bin
	; special case: single '0'. set Z if we hit have null terminating.
	or	a
.hexOrBinEnd:
	dec	hl \ dec hl	; replace HL
	ret			; Z already set

.hex:
	push	hl
	call	parseHexadecimal
	pop	hl
	jr	.hexOrBinEnd

.bin:
	call	parseBinaryLiteral
	jr	.hexOrBinEnd
