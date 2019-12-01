basBSEL:
	call	rdExpr
	ret	nz
	push	ix \ pop hl
	call	blkSelPtr
	ld	a, l
	jp	blkSel

basBSEEK:
	call	rdExpr
	ret	nz
	push	ix	; --> lvl 1
	call	rdExpr
	push	ix \ pop de
	pop	hl	; <-- lvl 1
	jr	z, .skip
	; DE not supplied, set to zero
	ld	de, 0
.skip:
	xor	a	; absolute mode
	call	blkSeek
	cp	a	; ensure Z
	ret

basGETB:
	call	blkGetB
	ret	nz
	ld	(VAR_TBL), a
	xor	a
	ld	(VAR_TBL+1), a
	ret

basPUTB:
	call	rdExpr
	ret	nz
	push	ix \ pop hl
	ld	a, l
	jp	blkPutB

basBLKCmds:
	.db	"bsel", 0
	.dw	basBSEL
	.db	"bseek", 0
	.dw	basBSEEK
	.db	"getb", 0
	.dw	basGETB
	.db	"putb", 0
	.dw	basPUTB
	.db	0xff		; end of table
