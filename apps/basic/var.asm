; *** Variables ***
; A list of words for each member of the A-Z range.
.equ	VAR_TBL		VAR_RAMSTART
.equ	VAR_RAMEND	@+52

; *** Code ***

varInit:
	ld	b, VAR_RAMEND-VAR_RAMSTART
	ld	hl, VAR_RAMSTART
	xor	a
.loop:
	ld	(hl), a
	inc	hl
	djnz	.loop
	ret

; Check if A is a valid variable letter (a-z or A-Z). If it is, set A to a
; valid VAR_TBL index and set Z. Otherwise, unset Z (and A is destroyed)
varChk:
	call	upcase
	sub	'A'
	ret	c	; Z unset
	cp	27	; 'Z' + 1
	jr	c, .isVar
	; A > 'Z'
	dec	a	; unset Z
	ret
.isVar:
	cp	a	; set Z
	ret

; Try to interpret line at (HL) and see if it's a variable assignment. If it
; is, proceed with the assignment and set Z. Otherwise, NZ.
varTryAssign:
	inc	hl
	ld	a, (hl)
	dec	hl
	cp	'='
	ret	nz
	ld	a, (hl)
	call	varChk
	ret	nz
	; We have a variable! Its table index is currently in A.
	push	ix	; --> lvl 1
	push	hl	; --> lvl 2
	push	de	; --> lvl 3
	push	af	; --> lvl 4. save for later
	; Let's put that expression to read in scratchpad
	inc	hl \ inc hl
	ld	de, SCRATCHPAD
	call	rdWord
	ex	de, hl
	; Now, evaluate that expression now in (HL)
	call	parseExpr	; --> number in DE
	jr	nz, .exprErr
	pop	af	; <-- lvl 4
	call	varAssign
	xor	a	; ensure Z
.end:
	pop	de	; <-- lvl 3
	pop	hl	; <-- lvl 2
	pop	ix	; <-- lvl 1
	ret
.exprErr:
	pop	af	; <-- lvl 4
	jr	.end

; Given a variable **index** in A (call varChk to transform) and a value in
; DE, assign that value in the proper cell in VAR_TBL.
; No checks are made.
varAssign:
	push	hl
	add	a, a	; * 2 because each element is a word
	ld	hl, VAR_TBL
	call	addHL
	; HL placed, write number
	ld	(hl), e
	inc	hl
	ld	(hl), d
	pop	hl
	ret

; Check if value at (HL) is a variable. If yes, returns its associated value.
; Otherwise, jump to parseLiteral.
parseLiteralOrVar:
	inc	hl
	ld	a, (hl)
	dec	hl
	or	a
	; if more than one in length, it can't be a variable
	jp	nz, parseLiteral
	ld	a, (hl)
	call	varChk
	jp	nz, parseLiteral
	; It's a variable, resolve!
	add	a, a	; * 2 because each element is a word
	push	hl	; --> lvl 1
	ld	hl, VAR_TBL
	call	addHL
	push	de	; --> lvl 2
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	push	de \ pop ix
	pop	de	; <-- lvl 2
	pop	hl	; <-- lvl 1
	cp	a	; ensure Z
	ret
