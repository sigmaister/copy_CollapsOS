; kbd
;
; Control TI-84+'s keyboard.
;
; *** Constants ***
.equ	KBD_PORT	0x01

; *** Code ***
; Sending 0xff to the port resets the keyboard, and then we have to send groups
; we want to "listen" to, with a 0 in the group bit. Thus, to know if *any* key
; is pressed, we send 0xff to reset the keypad, then 0x00 to select all groups,
; if the result isn't 0xff, at least one key is pressed.
waitForKey:
	push	af

	ld	a, 0xff
	out	(KBD_PORT), a
	ld	a, 0x00
	out	(KBD_PORT), a

.loop:
	in	a, (KBD_PORT)
	inc	a		; if a was 0xff, will become 0 (z test)
	jr	z, .loop	; zero? nothing pressed

	pop	af
	ret
