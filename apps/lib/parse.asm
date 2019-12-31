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


; Parse string at (HL) as a decimal value and return value in DE.
; Reads as many digits as it can and stop when:
; 1 - A non-digit character is read
; 2 - The number overflows from 16-bit
; HL is advanced to the character following the last successfully read char.
; Error conditions are:
; 1 - There wasn't at least one character that could be read.
; 2 - Overflow.
; Sets Z on success, unset on error.

parseDecimal:
	; First char is special: it has to succeed.
	ld	a, (hl)
	; Parse the decimal char at A and extract it's 0-9 numerical value. Put the
	; result in A.
	; On success, the carry flag is reset. On error, it is set.
	add	a, 0xff-'9'	; maps '0'-'9' onto 0xf6-0xff
	sub	0xff-9		; maps to 0-9 and carries if not a digit
	ret	c		; Error. If it's C, it's also going to be NZ
	; During this routine, we switch between HL and its shadow. On one side,
	; we have HL the string pointer, and on the other side, we have HL the
	; numerical result. We also use EXX to preserve BC, saving us a push.
	exx		; HL as a result
	ld	h, 0
	ld	l, a	; load first digit in without multiplying
	ld	b, 0	; We use B to detect overflow

.loop:
	exx		; HL as a string pointer
	inc hl
	ld a, (hl)
	exx		; HL as a numerical result

	; same as other above
	add	a, 0xff-'9'
	sub	0xff-9
	jr	c, .end

	add	hl, hl	; x2
	; We do this to detect overflow at each step
	rl	b
	ld	d, h
	ld	e, l		; de is x2
	add	hl, hl	; x4
	rl	b
	add	hl, hl	; x8
	rl	b
	add	hl, de	; x10
	rl	b
	ld	d, 0
	ld	e, a
	add	hl, de
	rl	b
	; Did we oveflow?
	xor	a
	or	b
	jr	z, .loop	; No? continue
	; error, NZ already set
	exx		; HL is now string pointer, restore BC
	; HL points to the char following the last success.
	ret

.end:
	push	hl	; --> lvl 1, result
	exx		; HL as a string pointer, restore BC
	pop	de	; <-- lvl 1, result
	cp	a	; ensure Z
	ret

; Call parseDecimal and then check that HL points to a whitespace or a null.
parseDecimalC:
	call	parseDecimal
	ret	nz
	ld	a, (hl)
	or	a
	ret	z		; null? we're happy
	jp	isWS

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
; HL is advanced to the character following the last successfully read char.
; Sets Z on success.
parseBinaryLiteral:
	ld	de, 0
.loop:
	ld	a, (hl)
	add	a, 0xff-'1'
	sub	0xff-1
	jr	c, .end
	rl	e
	add	a, e
	ld	e, a
	jp	c, unsetZ	; overflow
	inc	hl
	jr	.loop
.end:
	; HL is properly set
	xor	a		; ensure Z
	ret

; Parses the string at (HL) and returns the 16-bit value in DE. The string
; can be a decimal literal (1234), a hexadecimal literal (0x1234) or a char
; literal ('X').
; HL is advanced to the character following the last successfully read char.
;
; As soon as the number doesn't fit 16-bit any more, parsing stops and the
; number is invalid. If the number is valid, Z is set, otherwise, unset.
parseLiteral:
	ld	de, 0		; pre-fill
	ld	a, (hl)
	cp	0x27		; apostrophe
	jr	z, .char
	call	isDigit
	ret	nz
	cp	'0'
	jp	nz, parseDecimal
	; maybe hex, maybe binary
	inc	hl
	ld	a, (hl)
	inc	hl		; already place it for hex or bin
	cp	'x'
	jr	z, parseHexadecimal
	cp	'b'
	jr	z, parseBinaryLiteral
	; nope, just a regular decimal
	dec	hl \ dec hl
	jp	parseDecimal

; Parse string at (HL) and, if it is a char literal, sets Z and return
; corresponding value in E. D is always zero.
; HL is advanced to the character following the last successfully read char.
;
; A valid char literal starts with ', ends with ' and has one character in the
; middle. No escape sequence are accepted, but ''' will return the apostrophe
; character.
.char:
	inc	hl
	ld	e, (hl)		; our result
	inc	hl
	cp	(hl)
	jr	nz, .charError	; not ending with an apostrophe
	; good char, advance HL and return
	inc	hl
	; Z already set
	ret
.charError:
	; In all error conditions, HL is advanced by 2. Rewind.
	dec	hl \ dec hl
	; NZ already set
	ret


; Returns whether A is a literal prefix, that is, a digit or an apostrophe.
isLiteralPrefix:
	cp	0x27	; apostrophe
	ret	z
	; continue to isDigit

; Returns whether A is a digit
isDigit:
	cp	'0'
	jp	c, unsetZ
	cp	'9'+1
	jp	nc, unsetZ
	cp	a	; ensure Z
	ret
