
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
