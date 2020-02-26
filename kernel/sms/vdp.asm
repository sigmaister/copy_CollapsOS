; vdp - console on SMS' VDP
;
; Implement PutC on the console. Characters start at the top left. Every PutC
; call converts the ASCII char received to its internal font, then put that
; char on screen, advancing the cursor by one. When reaching the end of the
; line (33rd char), wrap to the next.
;
; In the future, there's going to be a scrolling mechanism when we reach the
; bottom of the screen, but for now, when the end of the screen is reached, we
; wrap up to the top.
;
; When reaching a new line, we clear that line and the next to help readability.
;
; *** Defines ***
; FNT_DATA: Pointer to 7x7 font data.
; *** Consts ***
;
.equ	VDP_CTLPORT	0xbf
.equ	VDP_DATAPORT	0xbe
.equ	VDP_COLS	32
.equ	VDP_ROWS	24

; *** Code ***

vdpInit:
	ld	hl, .initData
	ld	b, .initDataEnd-.initData
	ld	c, VDP_CTLPORT
	otir

	; Blank VRAM
	xor	a
	out	(VDP_CTLPORT), a
	ld	a, 0x40
	out	(VDP_CTLPORT), a
	ld	bc, 0x4000
.loop1:
	xor	a
	out	(VDP_DATAPORT), a
	dec	bc
	ld	a, b
	or	c
	jr	nz, .loop1

	; Set palettes
	xor	a
	out	(VDP_CTLPORT), a
	ld	a, 0xc0
	out	(VDP_CTLPORT), a
	ld	hl, .paletteData
	ld	b, .paletteDataEnd-.paletteData
	ld	c, VDP_DATAPORT
	otir

	; Define tiles
	xor	a
	out	(VDP_CTLPORT), a
	ld	a, 0x40
	out	(VDP_CTLPORT), a
	ld	hl, FNT_DATA
	ld	c, 0x7e-0x20	; range of displayable chars in font.
	; Each row in FNT_DATA is a row of the glyph and there is 7 of them.
	; We insert a blank one at the end of those 7. For each row we set, we
	; need to send 3 zero-bytes because each pixel in the tile is actually
	; 4 bits because it can select among 16 palettes. We use only 2 of them,
	; which is why those bytes always stay zero.
.loop2:
	ld	b, 7
.loop3:
	ld	a, (hl)
	out	(VDP_DATAPORT), a
	; send 3 blanks
	xor	a
	out	(VDP_DATAPORT), a
	nop	; the VDP needs 16 T-states to breathe
	out	(VDP_DATAPORT), a
	nop
	out	(VDP_DATAPORT), a
	inc	hl
	djnz	.loop3
	; Send a blank row after the 7th row
	xor	a
	out	(VDP_DATAPORT), a
	nop
	out	(VDP_DATAPORT), a
	nop
	out	(VDP_DATAPORT), a
	nop
	out	(VDP_DATAPORT), a
	dec	c
	jr	nz, .loop2

	; Bit 7 = ?, Bit 6 = display enabled
	ld	a, 0b11000000
	out	(VDP_CTLPORT), a
	ld	a, 0x81
	out	(VDP_CTLPORT), a
	ret

; VDP initialisation data
.initData:
; 0x8x == set register X
.db 0b00000100, 0x80	; Bit 2: Select mode 4
.db 0b00000000, 0x81
.db 0b11111111, 0x82	; Name table: 0x3800
.db 0b11111111, 0x85	; Sprite table: 0x3f00
.db 0b11111111, 0x86	; sprite use tiles from 0x2000
.db 0b11111111, 0x87	; Border uses palette 0xf
.db 0b00000000, 0x88	; BG X scroll
.db 0b00000000, 0x89	; BG Y scroll
.db 0b11111111, 0x8a	; Line counter (why have this?)
.initDataEnd:
.paletteData:
; BG palette
.db 0x00, 0x3f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
; Sprite palette (inverted colors)
.db 0x3f, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
.paletteDataEnd:

; Convert ASCII char in A into a tile index corresponding to that character.
; When a character is unknown, returns 0x5e (a '~' char).
vdpConv:
	; The font is organized to closely match ASCII, so this is rather easy.
	; We simply subtract 0x20 from incoming A
	sub	0x20
	cp	0x5f
	ret	c		; A < 0x5f, good
	ld	a, 0x5e
	ret

; grid routine. Sets cell at row D and column E to character A. If C is one, we
; use the sprite palette.
vdpSetCell:
	call	vdpConv
	; store A away
	ex	af, af'
	push	bc
	ld	b, 0		; we push rotated bits from D into B so
				; that we'll already have our low bits from the
				; second byte we'll send right after.
	; Here, we're fitting a 5-bit line, and a 5-bit column on 16-bit, right
	; aligned. On top of that, our righmost bit is taken because our target
	; cell is 2-bytes wide and our final number is a VRAM address.
	ld	a, d
	sla	a		; should always push 0, so no pushing in B
	sla	a		; same
	sla	a		; same
	sla	a \ rl b
	sla	a \ rl b
	sla	a \ rl b
	ld	c, a
	ld	a, e
	sla	a		; A * 2
	or	c		; bring in two low bits from D into high
				; two bits
	out	(VDP_CTLPORT), a
	ld	a, b		; 3 low bits set
	or	0x78		; 01 header + 0x3800
	out	(VDP_CTLPORT), a
	pop	bc

	; We're ready to send our data now. Let's go
	ex	af, af'
	out	(VDP_DATAPORT), a

	; Palette select is on bit 3 of MSB
	ld	a, 1
	and	c
	rla \ rla \ rla
	out	(VDP_DATAPORT), a
	ret

