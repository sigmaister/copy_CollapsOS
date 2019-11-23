; *** Requirements ***
; findchar
; multDEBC
; callIXI
;
; *** Defines ***
;
; EXPR_PARSE: routine to call to parse literals or symbols that are part of
;             the expression. Routine's signature:
;	      String in (HL), returns its parsed value to IX. Z for success.
;
; *** Code ***
;
; Parse expression in string at (HL) and returns the result in IX.
; **This routine mutates (HL).**
; We expect (HL) to be disposable: we mutate it to avoid having to make a copy.
; Sets Z on success, unset on error.
; TODO: the IX output register is a bit awkward. Nearly everywhere, I need
;       to push \ pop that thing. See if we could return the result in DE
;       instead.
parseExpr:
	push	de
	push	hl
	call	_parseExpr
	pop	hl
	pop	de
	ret

_parseExpr:
	ld	de, exprTbl
.loop:
	ld	a, (de)
	or	a
	jp	z, EXPR_PARSE	; no operator, just parse the literal
	push	de		; --> lvl 1. save operator row
	call	_findAndSplit
	jr	z, .found
	pop	de		; <-- lvl 1
	inc	de \ inc de \ inc de
	jr	.loop
.found:
	; Operator found, string splitted. Left in (HL), right in (DE)
	call	_resolveLeftAndRight
	; Whether _resolveLeftAndRight was a success, we pop our lvl 1 stack
	; out, which contains our operator row. We pop it in IX.
	; L-R numbers are parsed in HL (left) and DE (right).
	pop	ix		; <-- lvl 1
	ret	nz
	; Resolving left and right succeeded, proceed!
	inc	ix		; point to routine pointer
	call	callIXI
	push	de \ pop ix
	cp	a		; ensure Z
	ret

; Given a string in (HL) and a separator char in A, return a splitted string,
; that is, the same (HL) string but with the found A char replaced by a null
; char. DE points to the second part of the split.
; Sets Z if found, unset if not found.
_findAndSplit:
	push	hl
	call	.skipCharLiteral
	call	findchar
	jr	nz, .end	; nothing found
	; Alright, we have our char and we're pointing at it. Let's replace it
	; with a null char.
	xor	a
	ld	(hl), a		; + changed to \0
	inc	hl
	ex	de, hl		; DE now points to the second part of the split
	cp	a		; ensure Z
.end:
	pop	hl		; HL is back to the start
	ret

.skipCharLiteral:
	; special case: if our first char is ', skip the first 3 characters
	; so that we don't mistake a literal for an iterator
	push	af
	ld	a, (hl)
	cp	0x27		; '
	jr	nz, .skipCharLiteralEnd	; not a '
	xor	a	; check for null char during skipping
	; skip 3
	inc	hl
	cp	(hl)
	jr	z, .skipCharLiteralEnd
	inc	hl
	cp	(hl)
	jr	z, .skipCharLiteralEnd
	inc	hl
.skipCharLiteralEnd:
	pop	af
	ret
.find:

; parse expression on the left (HL) and the right (DE) and put the results in
; HL (left) and DE (right)
_resolveLeftAndRight:
	; special case: is (HL) zero? If yes, it means that our left operand
	; is empty. consider it as 0
	ld	ix, 0		; pre-set to 0
	ld	a, (hl)
	or	a
	jr	z, .skip
	; Parse left operand in (HL)
	call	parseExpr
	ret	nz		; return immediately if error
.skip:
	; Now we have parsed everything to the left and we have its result in
	; IX. What we need to do now is the same thing on (DE) and then apply
	; the + operator. Let's save IX somewhere and parse this.
	ex	de, hl	; right expr now in HL
	push	ix	; --> lvl 1
	call	parseExpr
	pop	hl	; <-- lvl 1. left
	push	ix \ pop de	; right
	ret		; Z is parseExpr's result

; Routines in here all have the same signature: they take two numbers, DE (left)
; and IX (right), apply the operator and put the resulting number in DE.
; The table has 3 bytes per row: 1 byte for operator and 2 bytes for routine
; pointer.
exprTbl:
	.db	'+'
	.dw	.plus
	.db	'-'
	.dw	.minus
	.db	'*'
	.dw	.mult
	.db	'/'
	.dw	.div
	.db	'%'
	.dw	.mod
	.db	'&'
	.dw	.and
	.db	0x7c		; '|'
	.dw	.or
	.db	'^'
	.dw	.xor
	.db	'}'
	.dw	.rshift
	.db	'{'
	.dw	.lshift
	.db	0		; end of table

.plus:
	add	hl, de
	ex	de, hl
	ret

.minus:
	or	a	; clear carry
	sbc	hl, de
	ex	de, hl
	ret

.mult:
	ld	b, h
	ld	c, l
	call	multDEBC	; --> HL
	ex	de, hl
	ret

.div:
	; divide takes HL/DE
	push	bc
	call	divide
	ld	e, c
	ld	d, b
	pop	bc
	ret

.mod:
	call	.div
	ex	de, hl
	ret

.and:
	ld	a, h
	and	d
	ld	d, a
	ld	a, l
	and	e
	ld	e, a
	ret
.or:
	ld	a, h
	or	d
	ld	d, a
	ld	a, l
	or	e
	ld	e, a
	ret

.xor:
	ld	a, h
	xor	d
	ld	d, a
	ld	a, l
	xor	e
	ld	e, a
	ret

.rshift:
	ld	a, e
	and	0xf
	ret	z
	push	bc
	ld	b, a
.rshiftLoop:
	srl	h
	rr	l
	djnz	.rshiftLoop
	ex	de, hl
	pop	bc
	ret

.lshift:
	ld	a, e
	and	0xf
	ret	z
	push	bc
	ld	b, a
.lshiftLoop:
	sla	l
	rl	h
	djnz	.lshiftLoop
	ex	de, hl
	pop	bc
	ret
