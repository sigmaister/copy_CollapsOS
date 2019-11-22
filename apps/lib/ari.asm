; Borrowed from Tasty Basic by Dimitri Theulings (GPL).
; Divide HL by DE, placing the result in BC and the remainder in HL.
divide:
	push hl		; --> lvl 1
	ld l, h		; divide h by de
	ld h, 0
	call .dv1
	ld b, c		; save result in b
	ld a, l		; (remainder + l) / de
	pop hl		; <-- lvl 1
	ld h, a
.dv1:
	ld c, 0xff	; result in c
.dv2:
	inc c		; dumb routine
	call .subde	; divide using subtract and count
	jr nc, .dv2
	add hl, de
	ret
.subde:
	ld a, l
	sub e		; subtract de from hl
	ld l, a
	ld a, h
	sbc a, d
	ld h, a
	ret

; DE * BC -> DE (high) and HL (low)
multDEBC:
	ld	hl, 0
	ld	a, 0x10
.loop:
	add	hl, hl
	rl	e
	rl	d
	jr	nc, .noinc
	add	hl, bc
	jr	nc, .noinc
	inc	de
.noinc:
	dec a
	jr	nz, .loop
	ret
