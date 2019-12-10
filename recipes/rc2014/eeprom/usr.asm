; If you find youself needing to write to an EEPROM through a shell that isn't
; built for this, compile this dependency-less code (change memory offsets as
; needed) and run it in a USR-like fashion.

	ld	bc, 0x1000	; bytecount to write
	ld	de, 0xd000	; source data
	ld	hl, 0x2000	; dest EEPROM memory mapping

loop:
	ld	a, (de)
	ld	(hl), a
	push	de		; --> lvl 1
	push	bc		; --> lvl 2
	ld	bc, 0x2000	; Should be plenty enough to go > 10ms
	ld	e, a		; save expected data for verification
wait:
	; as long as writing operation is running, IO/6 will toggle at each
	; read attempt and IO/7 will be the opposite of what was written. Simply
	; wait until the read operation yields the same value as what we've
	; written
	ld	a, (hl)
	cp	e
	jr	z, waitend
	dec	bc
	ld	a, b
	or	c
	jr	nz, wait
	; mismatch
	pop	bc		; <-- lvl 2
	pop	de		; <-- lvl 1
	ld	a, 1		; nonzero
	or	a		; unset Z
	ret
waitend:
	pop	bc		; <-- lvl 2
	pop	de		; <-- lvl 1
	inc	hl
	inc	de
	dec	bc
	ld	a, b
	or	c
	jr	nz, loop
	ret			; Z already set
