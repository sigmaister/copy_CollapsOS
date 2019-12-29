; *** Requirements ***
; ari
;
; *** Defines ***
;
; EXPR_PARSE: routine to call to parse literals or symbols that are part of
;             the expression. Routine's signature:
;	      String in (HL), returns its parsed value to DE. Z for success.
;
; *** Code ***
;
; Parse expression in string at (HL) and returns the result in DE.
; This routine needs to be able to mutate (HL), but it takes care of restoring
; the string to its original value before returning.
; Sets Z on success, unset on error.
parseExpr:
	push	iy
	push	ix
	push	hl
	call	_parseAddSubst
	pop	hl
	pop	ix
	pop	iy
	ret

; *** Op signature ***
; The signature of "operators routines" (.plus, .mult, etc) below is this:
; Combine HL and DE with an operator (+, -, *, etc) and put the result in DE.
; Destroys HL and A. Never fails. Yes, that's a problem for division by zero.
; Don't divide by zero. All other registers are protected.

; Given a running result in DE, a rest-of-expression in (HL), a parse routine
; in IY and an apply "operator routine" in IX, (HL/DE --> DE)
; With that, parse the rest of (HL) and apply the operation on it, then place
; HL at the end of the parsed string, with A containing the last char of it,
; which can be either an operator or a null char.
; Z for success.
;
_parseApply:
	push	de	; --> lvl 1, left result
	push	ix	; --> lvl 2, routine to apply
	inc	hl	; after op char
	call	callIY	; --> DE
	pop	ix	; <-- lvl 2, routine to apply
	; Here we do some stack kung fu. We have, in HL, a string pointer we
	; want to keep. We have, in (SP), our left result we want to use.
	ex	(sp), hl	; <-> lvl 1
	jr	nz, .end
	push	af	; --> lvl 2, save ending operator
	call	callIX
	pop	af	; <-- lvl 2, restore operator.
.end:
	pop	hl	; <-- lvl 1, restore str pointer
	ret

; Unless there's an error, this routine completely resolves any valid expression
; from (HL) and puts the result in DE.
; Destroys HL
; Z for success.
_parseAddSubst:
	call	_parseMultDiv
	ret	nz
.loop:
	; do we have an operator?
	or	a
	ret	z	; null char, we're done
	; We have an operator. Resolve the rest of the expr then apply it.
	ld	ix, .plus
	cp	'+'
	jr	z, .found
	ld	ix, .minus
	cp	'-'
	ret	nz		; unknown char, error
.found:
	ld	iy, _parseMultDiv
	call	_parseApply
	ret	nz
	jr	.loop
.plus:
	add	hl, de
	ex	de, hl
	ret
.minus:
	or	a		; clear carry
	sbc	hl, de
	ex	de, hl
	ret

; Parse (HL) as far as it can, that is, resolving expressions at its level or
; lower (anything but + and -).
; A is set to the last op it encountered. Unless there's an error, this can only
; be +, - or null. Null if we're done parsing, + and - if there's still work to
; do.
; (HL) points to last op encountered.
; DE is set to the numerical value of everything that was parsed left of (HL).
_parseMultDiv:
	call	_parseBitShift
	ret	nz
.loop:
	; do we have an operator?
	or	a
	ret	z	; null char, we're done
	; We have an operator. Resolve the rest of the expr then apply it.
	ld	ix, .mult
	cp	'*'
	jr	z, .found
	ld	ix, .div
	cp	'/'
	jr	z, .found
	ld	ix, .mod
	cp	'%'
	jr	z, .found
	; might not be an error, return success
	cp	a
	ret
.found:
	ld	iy, _parseBitShift
	call	_parseApply
	ret	nz
	jr	.loop

.mult:
	push	bc		; --> lvl 1
	ld	b, h
	ld	c, l
	call	multDEBC	; --> HL
	pop	bc		; <-- lvl 1
	ex	de, hl
	ret

.div:
	; divide takes HL/DE
	ld	a, l
	push	bc		; --> lvl 1
	call	divide
	ld	e, c
	ld	d, b
	pop	bc		; <-- lvl 1
	ret

.mod:
	call	.div
	ex	de, hl
	ret

; Same as _parseMultDiv, but a layer lower.
_parseBitShift:
	call	_parseNumber
	ret	nz
.loop:
	; do we have an operator?
	or	a
	ret	z	; null char, we're done
	; We have an operator. Resolve the rest of the expr then apply it.
	ld	ix, .and
	cp	'&'
	jr	z, .found
	ld	ix, .or
	cp	0x7c		; '|'
	jr	z, .found
	ld	ix, .xor
	cp	'^'
	jr	z, .found
	ld	ix, .rshift
	cp	'}'
	jr	z, .found
	ld	ix, .lshift
	cp	'{'
	jr	z, .found
	; might not be an error, return success
	cp	a
	ret
.found:
	ld	iy, _parseNumber
	call	_parseApply
	ret	nz
	jr	.loop

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
	push	bc		; --> lvl 1
	ld	b, a
.rshiftLoop:
	srl	h
	rr	l
	djnz	.rshiftLoop
	ex	de, hl
	pop	bc		; <-- lvl 1
	ret

.lshift:
	ld	a, e
	and	0xf
	ret	z
	push	bc		; --> lvl 1
	ld	b, a
.lshiftLoop:
	sla	l
	rl	h
	djnz	.lshiftLoop
	ex	de, hl
	pop	bc		; <-- lvl 1
	ret

; Parse first number of expression at (HL). A valid number is anything that can
; be parsed by EXPR_PARSE and is followed either by a null char or by any of the
; operator chars. This routines takes care of replacing an operator char with
; the null char before calling EXPR_PARSE and then replace the operator back
; afterwards.
; HL is moved to the char following the number having been parsed.
; DE contains the numerical result.
; A contains the operator char following the number (or null). Only on success.
; Z for success.
_parseNumber:
	; Special case 1: number starts with '-'
	ld	a, (hl)
	cp	'-'
	jr	nz, .skip1
	; We have a negative number. Parse normally, then subst from zero
	inc	hl
	call	_parseNumber
	push	hl		; --> lvl 1
	ex	af, af'		; preserve flags
	or	a		; clear carry
	ld	hl, 0
	sbc	hl, de
	ex	de, hl
	ex	af, af'		; restore flags
	pop	hl		; <-- lvl 1
	ret
.skip1:
	; End of special case 1
	; Copy beginning of string to DE, we'll need it later
	ld	d, h
	ld	e, l

	; Special case 2: we have a char literal. If we have a char literal, we
	; don't want to go through the "_isOp" loop below because if that char
	; is one of our operators, we're messing up our processing. So, set
	; ourselves 3 chars further and continue from there. EXPR_PARSE will
	; take care of validating those 3 chars.
	cp	0x27		; apostrophe (') char
	jr	nz, .skip2
	; "'". advance HL by 3
	inc	hl \ inc hl \ inc hl
	; End of special case 2
.skip2:

	dec	hl	; offset "inc-hl-before" in loop
.loop:
	inc	hl
	ld	a, (hl)
	call	_isOp
	jr	nz, .loop
	; (HL) and A is an op or a null
	push	af	; --> lvl 1 save op
	push	hl	; --> lvl 2 save end of string
	; temporarily put a null char instead of the op
	xor	a
	ld	(hl), a
	ex	de, hl	; rewind to beginning of number
	call	EXPR_PARSE	; --> DE
	ex	af, af'		; keep result flags away while we restore (HL)
	pop	hl	; <-- lvl 2, end of string
	pop	af	; <-- lvl 1, saved op
	ld	(hl), a
	ex	af, af'		; restore Z from EXPR_PARSE
	ret	nz
	; HL is currently at the end of the number's string
	; On success, have A be the operator char following the number
	ex	af, af'
	ret

; Sets Z if A contains a valid operator char or a null char.
_isOp:
	or	a
	ret	z
	push	hl	; --> lvl 1
	; Set A' to zero for quick end-of-table checks
	ex	af, af'
	xor	a
	ex	af, af'
	ld	hl, .exprChars
.loop:
	cp	(hl)
	jr	z, .found
	ex	af, af'
	cp	(hl)
	jr	z, .notFound	; end of table
	ex	af, af'
	inc	hl		; next char
	jr	.loop
.notFound:
	ex	af, af'			; restore orig A
	inc	a			; unset Z
.found:
	; Z already set
	pop	hl	; <-- lvl 1
	ret

.exprChars:
	.db	"+-*/%&|^{}", 0

