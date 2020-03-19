; The Parameter stack (PS) is maintained by SP and the Return stack (RS) is
; maintained by IX. This allows us to generally use push and pop freely because
; PS is the most frequently used. However, this causes a problem with routine
; calls: because in Forth, the stack isn't balanced within each call, our return
; offset, when placed by a CALL, messes everything up. This is one of the
; reasons why we need stack management routines below. IX always points to RS'
; Top Of Stack (TOS)
;
; This return stack contain "Interpreter pointers", that is a pointer to the
; address of a word, as seen in a compiled list of words.

; Push value HL to RS
pushRS:
	inc	ix
	inc	ix
	ld	(ix), l
	ld	(ix+1), h
	ret

; Pop RS' TOS to HL
popRS:
	ld	l, (ix)
	ld	h, (ix+1)
	dec ix
	dec ix
	ret

popRSIP:
	call	popRS
	ld	(IP), hl
	ret

; Skip the next two bytes in RS' TOS
skipRS:
	push	hl
	ld	l, (ix)
	ld	h, (ix+1)
	inc	hl \ inc hl
	ld	(ix), l
	ld	(ix+1), h
	pop	hl
	ret

; Verifies that SP and RS are within bounds. If it's not, call ABORT
chkRS:
	push	ix \ pop hl
	push	de		; --> lvl 1
	ld	de, RS_ADDR
	or	a		; clear carry
	sbc	hl, de
	pop	de		; <-- lvl 1
	jp	c, abortUnderflow
	ret

chkPS:
	push	hl
	ld	hl, (INITIAL_SP)
	; We have the return address for this very call on the stack and
	; protected registers. Let's compensate
	dec	hl \ dec hl
	dec	hl \ dec hl
	or	a		; clear carry
	sbc	hl, sp
	pop	hl
	ret	nc		; (INITIAL_SP) >= SP? good
	jp	abortUnderflow
