; vid - TRS-80's video
;
; Implement PutC using TRS-80's SVC calls so that character it put on video
; display.

trs80PutC:
	push	af
	push	bc
	push	de		; altered by SVC
	ld	c, a
	ld	a, 0x02		; @DSP
	rst	0x28
	pop	de
	pop	bc
	pop	af
	ret
