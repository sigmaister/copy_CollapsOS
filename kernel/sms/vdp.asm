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

; *** Variables ***
;
; Row of cursor
.equ	VDP_ROW		VDP_RAMSTART
; Line of cursor
.equ	VDP_LINE	@+1
.equ	VDP_RAMEND	@+1

; *** Code ***

vdpInit:
	xor	a
	ld	(VDP_ROW), a
	ld	(VDP_LINE), a

	ld	hl, vdpInitData
	ld	b, vdpInitDataEnd-vdpInitData
	ld	c, VDP_CTLPORT
	otir

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

	xor	a
	out	(VDP_CTLPORT), a
	ld	a, 0xc0
	out	(VDP_CTLPORT), a
	ld	hl, vdpPaletteData
	ld	b, vdpPaletteDataEnd-vdpPaletteData
	ld	c, VDP_DATAPORT
	otir

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

	ld	a, 0b11000000
	out	(VDP_CTLPORT), a
	ld	a, 0x81
	out	(VDP_CTLPORT), a
	ret

; Spits char set in A at current cursor position. Doesn't move the cursor.
; A is a "sega" char
vdpSpitC:
	; store A away
	ex	af, af'
	push	bc
	ld	b, 0		; we push rotated bits from VDP_LINE into B so
				; that we'll already have our low bits from the
				; second byte we'll send right after.
	; Here, we're fitting a 5-bit line, and a 5-bit column on 16-bit, right
	; aligned. On top of that, our righmost bit is taken because our target
	; cell is 2-bytes wide and our final number is a VRAM address.
	ld	a, (VDP_LINE)
	sla	a		; should always push 0, so no pushing in B
	sla	a		; same
	sla	a		; same
	sla	a \ rl b
	sla	a \ rl b
	sla	a \ rl b
	ld	c, a
	ld	a, (VDP_ROW)
	sla	a		; A * 2
	or	c		; bring in two low bits from VDP_LINE into high
				; two bits
	out	(VDP_CTLPORT), a
	ld	a, b		; 3 low bits set
	or	0x78
	out	(VDP_CTLPORT), a
	pop	bc

	; We're ready to send our data now. Let's go
	ex	af, af'
	out	(VDP_DATAPORT), a
	ret

vdpPutC:
	; Then, let's place our cursor. We need to first send our LSB, whose
	; 6 low bits contain our row*2 (each tile is 2 bytes wide) and high
	; 2 bits are the two low bits of our line
	; special case: line feed, carriage return, back space
	cp	LF
	jr	z, vdpLF
	cp	CR
	jr	z, vdpCR
	cp	BS
	jr	z, vdpBS

	push	af

	; ... but first, let's convert it.
	call	vdpConv

	; and spit it on screen
	call	vdpSpitC

	; Move cursor. The screen is 32x24
	ld	a, (VDP_ROW)
	cp	31
	jr	z, .incline
	; We just need to increase row
	inc	a
	ld	(VDP_ROW), a

	pop	af
	ret
.incline:
	; increase line and start anew
	call	vdpCR
	call	vdpLF
	pop	af
	ret

vdpCR:
	call	vdpClrPos
	push	af
	xor	a
	ld	(VDP_ROW), a
	pop	af
	ret

vdpLF:
	; we don't call vdpClrPos on LF because we expect it to be preceded by
	; a CR, which already cleared the pos. If we cleared it now, we would
	; clear the first char of the line.
	push	af
	ld	a, (VDP_LINE)
	call	.incA
	call	vdpClrLine
	; Also clear the line after this one
	push	af		; --> lvl 1
	call	.incA
	call	vdpClrLine
	pop	af		; <-- lvl 1
	ld	(VDP_LINE), a
	pop	af
	ret
.incA:
	inc	a
	cp	24
	ret	nz	; no rollover
	; bottom reached, roll over to top of screen
	xor	a
	ret

vdpBS:
	call	vdpClrPos
	push	af
	ld	a, (VDP_ROW)
	or	a
	jr	z, .lineup
	dec	a
	ld	(VDP_ROW), a
	pop	af
	ret
.lineup:
	; end of line
	ld	a, 31
	ld	(VDP_ROW), a
	; we have to go one line up
	ld	a, (VDP_LINE)
	or	a
	jr	z, .nowrap
	; We have to wrap to the bottom of the screen
	ld	a, 24
.nowrap:
	dec	a
	ld	(VDP_LINE), a
	pop	af
	ret

; Clear tile under cursor
vdpClrPos:
	push	af
	xor	a		; space
	call	vdpSpitC
	pop	af
	ret

; Clear line number A
vdpClrLine:
	; see comments in vdpSpitC for VRAM details.
	push	af
	; first, get the two LSB at MSB pos.
	rrca \ rrca
	push	af	; --> lvl 1
	and	0b11000000
	; That's our first address byte
	out	(VDP_CTLPORT), a
	pop	af	; <-- lvl 1
	; Then, get those 3 other bits at LSB pos. Our popped A has already
	; done 2 RRCA, which means that everything is in place.
	and	0b00000111
	or	0x78
	out	(VDP_CTLPORT), a
	; We're at the right place. Let's just spit 32*2 null bytes
	xor	a
	push	bc	; --> lvl 1
	ld	b, 64
.loop:
	out	(VDP_DATAPORT), a
	djnz	.loop
	pop	bc	; <-- lvl 1
	pop	af
	ret

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

vdpPaletteData:
.db 0x00,0x3f
vdpPaletteDataEnd:

; VDP initialisation data
vdpInitData:
.db 0x04,0x80,0x00,0x81,0xff,0x82,0xff,0x85,0xff,0x86,0xff,0x87,0x00,0x88,0x00,0x89,0xff,0x8a
vdpInitDataEnd:
