; kbd - TRS-80 keyboard
;
; Implement GetC for TRS-80's keyboard using the system's SVCs.

trs80GetC:
	push	de	; altered by SVC
	ld	a, 0x01	; @KEY
	rst	0x28	; --> A
	pop	de
	ret
