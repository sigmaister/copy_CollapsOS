; Parse an expression yielding a truth value from (HL) and set A accordingly.
; 0 for False, nonzero for True.
; How it evaluates truth is that it looks for =, <, >, >= or <= in (HL) and,
; if it finds it, evaluate left and right expressions separately. Then it
; compares both sides and set A accordingly.
; If comparison operators aren't found, the whole string is sent to parseExpr
; and zero means False, nonzero means True.
; **This routine mutates (HL).**
; Z for success.
parseTruth:
	push	ix
	push	de
	ld	a, '='
	call	.maybeFind
	jr	z, .foundEQ
	ld	a, '<'
	call	.maybeFind
	jr	z, .foundLT
	ld	a, '>'
	call	.maybeFind
	jr	z, .foundGT
	jr	.simple
.success:
	cp	a	; ensure Z
.end:
	pop	de
	pop	ix
	ret

.maybeFind:
	push	hl	; --> lvl 1
	call	findchar
	jr	nz, .notFound
	; found! We want to keep new HL around. Let's pop old HL in DE
	pop	de	; <-- lvl 1
	ret
.notFound:
	; not found, restore HL
	pop	hl	; <-- lvl 1
	ret

.simple:
	call	parseExpr
	jr	nz, .end
	ld	a, d
	or	e
	jr	.success

.foundEQ:
	; we found an '=' char and HL is pointing to it. DE is pointing to the
	; beginning of our string. Let's separate those two strings.
	; But before we do that, to we have a '<' or a '>' at the left of (HL)?
	dec	hl
	ld	a, (hl)
	cp	'<'
	jr	z, .foundLTE
	cp	'>'
	jr	z, .foundGTE
	inc	hl
	; Ok, we are a straight '='. Proceed.
	call	.splitLR
	; HL now point to right-hand, DE to left-hand
	call	.parseLeftRight
	jr	nz, .end	; error, stop
	xor	a		; clear carry and prepare value for False
	sbc	hl, de
	jr	nz, .success	; NZ? equality not met. A already 0, return.
	; Z? equality met, make A=1, set Z
	inc	a
	jr	.success

.foundLTE:
	; Almost the same as '<', but we have two sep chars
	call	.splitLR
	inc	hl	; skip the '=' char
	call	.parseLeftRight
	jr	nz, .end
	ld	a, 1		; prepare for True
	sbc	hl, de
	jr	nc, .success	; Left <= Right, True
	; Left > Right, False
	dec	a
	jr	.success

.foundGTE:
	; Almost the same as '<='
	call	.splitLR
	inc	hl	; skip the '=' char
	call	.parseLeftRight
	jr	nz, .end
	ld	a, 1		; prepare for True
	sbc	hl, de
	jr	z, .success	; Left == Right, True
	jr	c, .success	; Left > Right, True
	; Left < Right, False
	dec	a
	jr	.success

.foundLT:
	; Same thing as EQ, but for '<'
	call	.splitLR
	call	.parseLeftRight
	jr	nz, .end
	xor	a
	sbc	hl, de
	jr	z, .success	; Left == Right, False
	jr	c, .success	; Left > Right, False
	; Left < Right, True
	inc	a
	jr	.success

.foundGT:
	; Same thing as EQ, but for '>'
	call	.splitLR
	call	.parseLeftRight
	jr	nz, .end
	xor	a
	sbc	hl, de
	jr	nc, .success	; Left <= Right, False
	; Left > Right, True
	inc	a
	jr	.success

.splitLR:
	xor	a
	ld	(hl), a
	inc	hl
	ret

; Given string pointers in (HL) and (DE), evaluate those two expressions and
; place their corresponding values in HL and DE.
.parseLeftRight:
	; let's start with HL
	push	de		; --> lvl 1
	call	parseExpr
	pop	hl		; <-- lvl 1, orig DE
	ret	nz
	push	de		; --> lvl 1. save HL value in stack.
	; Now, for DE. (DE) is now in HL
	call	parseExpr	; DE in place
	pop	hl		; <-- lvl 1. restore saved HL
	ret
