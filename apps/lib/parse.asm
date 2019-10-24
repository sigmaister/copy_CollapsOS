; *** Requirements ***
; None
;
; *** Code ***

; Parse the decimal char at A and extract it's 0-9 numerical value. Put the
; result in A.
;
; On success, the carry flag is reset. On error, it is set.
; Also, zero flag set if '0'
; parseDecimalDigit has been replaced with the following code inline:
;	add	a, 0xff-'9'	; maps '0'-'9' onto 0xf6-0xff
;	sub	0xff-9		; maps to 0-9 and carries if not a digit

; Parse string at (HL) as a decimal value and return value in IX under the
; same conditions as parseLiteral.
; Sets Z on success, unset on error.

parseDecimal:
	push 	hl

	ld 	a, (hl)
	add	a, 0xff-'9'	; maps '0'-'9' onto 0xf6-0xff
	sub	0xff-9		; maps to 0-9 and carries if not a digit
	exx		; preserve bc, hl, de
	ld	h, 0
	ld	l, a	; load first digit in without multiplying
	ld	b, 3	; Carries can only occur for decimals >=5 in length
	jr	c, .end

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
	push	hl \ pop ix
	exx	; restore original de and bc
	pop	hl
	ret
