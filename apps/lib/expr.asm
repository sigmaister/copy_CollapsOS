; *** Requirements ***
; findchar
; multDEBC
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
	; out, which contains our operator row. We pop it in HL because we
	; don't need our string anymore. L-R numbers are parsed, and in DE and
	; IX.
	pop	hl		; <-- lvl 1
	ret	nz
	; Resolving left and right succeeded, proceed!
	inc	hl		; point to routine pointer
	call	intoHL
	jp	(hl)

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
; DE (left) and IX (right)
_resolveLeftAndRight:
	call	parseExpr
	ret	nz		; return immediately if error
	; Now we have parsed everything to the left and we have its result in
	; IX. What we need to do now is the same thing on (DE) and then apply
	; the + operator. Let's save IX somewhere and parse this.
	ex	de, hl	; right expr now in HL
	push	ix
	pop	de	; numeric left expr result in DE
	jp	parseExpr

; Routines in here all have the same signature: they take two numbers, DE (left)
; and IX (right), apply the operator and put the resulting number in IX.
; The table has 3 bytes per row: 1 byte for operator and 2 bytes for routine
; pointer.
exprTbl:
	.db	'+'
	.dw	.plus
	.db	'-'
	.dw	.minus
	.db	'*'
	.dw	.mult
	.db	0		; end of table

.plus:
	add	ix, de
	cp	a		; ensure Z
	ret

.minus:
	push	ix
	pop	hl
	ex	de, hl
	scf \ ccf
	sbc	hl, de
	push	hl
	pop	ix
	cp	a		; ensure Z
	ret

.mult:
	push	ix \ pop bc
	call	multDEBC
	push	hl \ pop ix
	cp	a		; ensure Z
	ret
