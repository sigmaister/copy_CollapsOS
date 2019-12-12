; Compare HL with DE and sets Z and C in the same way as a regular cp X where
; HL is A and DE is X.
cpHLDE:
	push 	hl
	or 	a		;reset carry flag
	sbc 	hl, de		;There is no 'sub hl, de', so we must use sbc
	pop 	hl
	ret
