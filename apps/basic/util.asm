; Is (HL) a double-quoted string? If yes, spit what's inside and place (HL)
; at char after the closing quote.
; Set Z if there was a string, unset otherwise.
spitQuoted:
	ld	a, (hl)
	cp	'"'
	ret	nz
	inc	hl
.loop:
	ld	a, (hl)
	inc	hl
	cp	'"'
	ret	z
	call	stdioPutC
	jr	.loop
