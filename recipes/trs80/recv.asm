.equ	COM_DRV_ADDR	0x0238	; replace with *CL's DCB addr
.equ	DEST_ADDR	0x3000	; memory address where to put contents.

; We process the 0x20 exception by pre-putting a mask in the (HL) we're going
; to write to. If it wasn't a 0x20, we put a 0xff mask. If it was a 0x20, we
; put a 0x7f mask.

	ld	hl, DEST_ADDR
loop:
	ld	a, 0xff
	ld	(hl), a		; default mask
loop2:
	ld	a, 0x03		; @GET
	ld	de, COM_DRV_ADDR
	rst	0x28
	jr	nz, maybeerror
	or	a
	ret	z		; Sending a straight NULL ends the comm.
	; @PUT that char back
	ld	c, a
	ld	a, 0x04		; @PUT
	rst	0x28
	jr	nz, error
	ld	a, c
	cp	0x20
	jr	z, escapechar
	; not an escape char, just apply the mask and write
	and	(hl)
	ld	(hl), a
	inc	hl
	jr	loop
escapechar:
	; adjust by setting (hl) to 0x7f
	res	7, (hl)
	jr	loop2
maybeerror:
	; was it an error?
	or	a
	jr	z, loop2	; not an error, just loop
	; error
error:
	ld	c, a		; Error code from @GET/@PUT
	ld	a, 0x1a		; @ERROR
	rst	0x28
	ret
