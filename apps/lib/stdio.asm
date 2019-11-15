; *** Requirements ***
; printnstr
;
; *** Variables ***
; Used to store formatted hex values just before printing it.
.equ	STDIO_HEX_FMT	STDIO_RAMSTART
.equ	STDIO_RAMEND	@+2

; *** Code ***
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

; Formats value in A into a string hex pair. Stores it in the memory location
; that HL points to. Does *not* add a null char at the end.
fmtHexPair:
	push	af

	; let's start with the rightmost char
	inc	hl
	call	fmtHex
	ld	(hl), a

	; and now with the leftmost
	dec	hl
	pop	af
	push	af
	rra \ rra \ rra \ rra
	call	fmtHex
	ld	(hl), a

	pop	af
	ret

; Print the hex char in A
printHex:
	push	bc
	push	hl
	ld	hl, STDIO_HEX_FMT
	call	fmtHexPair
	ld	b, 2
	call	printnstr
	pop	hl
	pop	bc
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


