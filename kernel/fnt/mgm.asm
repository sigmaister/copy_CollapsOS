; Font management
;
; There can only ever be one active font.
;
; *** Defines ***
; FNT_DATA: Pointer to the beginning of the binary font data to work with.
; FNT_WIDTH: Width of the font.
; FNT_HEIGHT: Height of the font.
;
; *** Code ***

; If A is in the range 0x20-0x7e, make HL point to the beginning of the
; corresponding glyph and set Z to indicate success.
; If A isn't in the range, do nothing and unset Z.
fntGet:
	cp	0x20
	ret	c	; A < 0x20. Z was unset by cp
	cp	0x7f
	jp	nc, unsetZ	; A >= 0x7f. Z might be set
	
	push	af	; --> lvl 1
	push	bc	; --> lvl 2
	sub	0x20
	ld	hl, FNT_DATA
	ld	b, FNT_HEIGHT
.loop:
	call	addHL
	djnz	.loop
	pop	bc	; <-- lvl 2
	pop	af	; <-- lvl 1
	cp	a	; set Z
	ret
