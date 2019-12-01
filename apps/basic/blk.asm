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
	.dw	basBSEL
	.db	"bsel", 0, 0
	.dw	basBSEEK
	.db	"bseek", 0
	.dw	basGETB
	.db	"getb", 0, 0
	.dw	basPUTB
	.db	"putb", 0, 0
	.db	0xff, 0xff, 0xff	; end of table
