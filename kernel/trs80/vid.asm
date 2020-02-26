; vid - TRS-80's video
;
; Implement PutC and GRID_SETCELL using TRS-80's SVC calls.

.equ	TRS80_COLS	80
.equ	TRS80_ROWS	24

trs80PutC:
	push	af
	push	bc
	push	de		; altered by SVC
	ld	c, a
	ld	a, 0x02		; @DSP
	rst	0x28
	pop	de
	pop	bc
	pop	af
	ret

trs80SetCell:
	push	af
	push	bc
	push	hl		; HL altered by @VDCTL
	push	de		; DE altered by @VDCTL
	ex	de, hl
	bit	0, c
	ld	c, a		; save A now
	jr	z, .skip	; Z from BIT above. cursor not set
	; set cursor
	ld	a, 0x0f		; @VDCTL
	ld	b, 3		; move cursor fn
	rst	0x28
	; HL altered.
	; Our Row/Col is our currently-pushed DE value. Let's take advantage of
	; that.
	pop	hl \ push hl	; HL altered. bring back from stack
.skip:
	ld	a, 0x0f		; @VDCTL
	ld	b, 2		; display char
	rst	0x28
	pop	de
	pop	hl
	pop	bc
	pop	af
	ret

; This is a much faster version of gridPushScr. Use it in your glue code, but
; you need to set HL to GRID_BUF first.
trs80PushScr:
	push	af
	push	bc
	ld	a, 0x0f		; @VDCTL
	ld	b, 5		; move from RAM to vid
	; HL is already set by caller
	rst	0x28
	pop	bc
	pop	af
	cp	a		; ensure Z
	ret
