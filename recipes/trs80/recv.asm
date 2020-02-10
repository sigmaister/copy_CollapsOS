	ld	hl, 0x3000	; memory address where to put contents.
loop:
	ld	a, 0x03		; @GET
	ld	de, 0xffff	; replace with *CL's DCB addr
	rst	0x28
	jr	nz, maybeerror
	or	a
	ret	z		; Sending a straight NULL ends the comm.
	; @PUT that char back
	ld	c, a
	ld	a, 0x04		; @PUT
	ld	de, 0xffff	; replace with *CL's DCB addr
	rst	0x28
	jr	nz, error
	ld	a, c
	cp	0x20
	jr	z, adjust
write:
	ld	(hl), a
	inc	hl
	jr	loop
adjust:
	dec	hl
	ld	a, (hl)
	and	0x7f
	jr	write
maybeerror:
	; was it an error?
	or	a
	jr	z, loop		; not an error, just loop
	; error
error:
	ld	c, a		; Error code from @GET/@PUT
	ld	a, 0x1a		; @ERROR
	rst	0x28
	ret
