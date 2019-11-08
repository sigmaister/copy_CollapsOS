; kbd
;
; Control TI-84+'s keyboard.
;
; *** Constants ***
.equ	KBD_PORT	0x01

; *** Code ***

; Wait for a digit to be pressed and sets the A register to the value (0-9) of
; that digit.
;
; This routine waits for a key to be pressed, but before that, it waits for
; all keys to be de-pressed. It does that to ensure that two calls to
; waitForKey only go through after two actual key presses (otherwise, the user
; doesn't have enough time to de-press the button before the next waitForKey
; routine registers the same key press as a second one).
; 
; Sending 0xff to the port resets the keyboard, and then we have to send groups
; we want to "listen" to, with a 0 in the group bit. Thus, to know if *any* key
; is pressed, we send 0xff to reset the keypad, then 0x00 to select all groups,
; if the result isn't 0xff, at least one key is pressed.
kbdGetC:
	push	bc

; loop until a digit is pressed
.loop:
	; When we check for digits, we go through all 3 groups containing them.
	; for each group, we load the digit we check for in B and then test the
	; bit for that key. If the bit is reset, our key is pressed. we can
	; jump to the end, copy B into A and return.

	; check group 2
	ld	a, 0xfb
	call	.get

	ld	b, '3'
	bit	1, a
	jr	z, .end

	ld	b, '6'
	bit	2, a
	jr	z, .end

	ld	b, '9'
	bit	3, a
	jr	z, .end

	ld	a, 0xf7
	call	.get

	ld	b, '2'
	bit	1, a
	jr	z, .end

	ld	b, '5'
	bit	2, a
	jr	z, .end

	ld	b, '8'
	bit	3, a
	jr	z, .end

	; check group 4
	ld	a, 0xef
	call	.get

	ld	b, '0'
	bit	0, a
	jr	z, .end

	ld	b, '1'
	bit	1, a
	jr	z, .end

	ld	b, '4'
	bit	2, a
	jr	z, .end

	ld	b, '7'
	bit	3, a
	jr	z, .end

	jr	.loop		; nothing happened? loop

.end:
	; loop until all keys are de-pressed
.loop2:
	xor	a
	call	.get
	inc	a		; if a was 0xff, will become 0 (nz test)
	jr	nz, .loop2	; non-zero? something is pressed

	; copy result into A
	ld	a, b

	pop	bc
	ret
.get:
	ex	af, af'
	ld	a, 0xff
	di
	out	(KBD_PORT), a
	ex	af, af'
	out	(KBD_PORT), a
	in	a, (KBD_PORT)
	ei
	ret
