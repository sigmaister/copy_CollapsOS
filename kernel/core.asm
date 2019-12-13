; core
;
; Routines used pretty much all everywhere. Unlike all other kernel units,
; this unit is designed to be included directly by userspace apps, not accessed
; through jump tables. The reason for this is that jump tables are a little
; costly in terms of machine cycles and that these routines are not very costly
; in terms of binary space.
; Therefore, this unit has to stay small and tight because it's repeated both
; in the kernel and in userspace. It should also be exclusively for routines
; used in the kernel.

; add the value of A into DE
addDE:
	push	af
	add	a, e
	jr	nc, .end	; no carry? skip inc
	inc	d
.end:
	ld	e, a
	pop	af
noop:				; piggy backing on the first "ret" we have
	ret

; add the value of A into HL
; affects carry flag according to the 16-bit addition, Z, S and P untouched.
addHL:
	push	de
	ld 	d, 0
	ld	e, a
	add	hl, de
	pop	de
	ret


; copy (HL) into DE, then exchange the two, utilising the optimised HL instructions.
; ld must be done little endian, so least significant byte first.
intoHL:
	push 	de
	ld 	e, (hl)
	inc 	hl
	ld 	d, (hl)
	ex 	de, hl
	pop 	de
	ret

intoDE:
	ex 	de, hl
	call 	intoHL
	ex 	de, hl		; de preserved by intoHL, so no push/pop needed
	ret

intoIX:
	push 	ix
	ex 	(sp), hl	;swap hl with ix, on the stack
	call 	intoHL
	ex 	(sp), hl	;restore hl from stack
	pop 	ix
	ret

; Call the method (IX) is a pointer to. In other words, call intoIX before
; callIX
callIXI:
	push	ix
	call	intoIX
	call	callIX
	pop	ix
	ret

; jump to the location pointed to by IX. This allows us to call IX instead of
; just jumping it. We use IX because we seldom use this for arguments.
callIX:
	jp	(ix)

callIY:
	jp	(iy)

; Ensures that Z is unset (more complicated than it sounds...)
; There are often better inline alternatives, either replacing rets with
; appropriate jmps, or if an 8 bit register is known to not be 0, an inc
; then a dec. If a is nonzero, 'or a' is optimal.
unsetZ:
	or 	a	;if a nonzero, Z reset
	ret	nz
	cp 	1	;if a is zero, Z reset
	ret
