; lcd
;
; Implement PutC on TI-84+ (for now)'s LCD screen.
;
; *** Requirements ***
; fnt/mgm
;
; *** Constants ***
.equ	LCD_PORT_CMD		0x10
.equ	LCD_PORT_DATA		0x11

.equ	LCD_CMD_6BIT		0x00
.equ	LCD_CMD_DISABLE		0x02
.equ	LCD_CMD_ENABLE		0x03
.equ	LCD_CMD_XINC		0x05
.equ	LCD_CMD_YINC		0x07
.equ	LCD_CMD_COL		0x20
.equ	LCD_CMD_ROW		0x80
.equ	LCD_CMD_CONTRAST	0xc0

; *** Code ***
lcdInit:
	; Enable the LCD
	ld	a, LCD_CMD_ENABLE
	call	lcdWait
	out	(LCD_PORT_CMD), a

	; Hack to get LCD to work. According to WikiTI, we're to sure why TIOS
	; sends these, but it sends it, and it is required to make the LCD
	; work. So...
	ld	a, 0x17
	call	lcdWait
	out	(LCD_PORT_CMD), a
	ld	a, 0x0b
	call	lcdWait
	out	(LCD_PORT_CMD), a

	; Set some usable contrast
	ld	a, LCD_CMD_CONTRAST+0x34
	call	lcdWait
	out	(LCD_PORT_CMD), a

	; Enable 6-bit mode.
	ld	a, LCD_CMD_6BIT
	call	lcdWait
	out	(LCD_PORT_CMD), a

	; Enable X-increment mode
	ld	a, LCD_CMD_XINC
	call	lcdWait
	out	(LCD_PORT_CMD), a

	ret

; Wait until the lcd is ready to receive a command
lcdWait:
	push	af
.loop:
	in	a, (LCD_PORT_CMD)
	; When 7th bit is cleared, we can send a new command
	rla
	jr	c, .loop
	pop	af
	ret

; Turn LCD off
lcdOff:
	ld	a, LCD_CMD_DISABLE
	call	lcdWait
	out	(LCD_PORT_CMD), a
	ret

; Set LCD's current column to A
lcdSetCol:
	; The col index specified in A is compounded with LCD_CMD_COL
	add	a, LCD_CMD_COL
	call	lcdWait
	out	(LCD_PORT_CMD), a
	ret

; Set LCD's current row to A
lcdSetRow:
	; The col index specified in A is compounded with LCD_CMD_COL
	add	a, LCD_CMD_ROW
	call	lcdWait
	out	(LCD_PORT_CMD), a
	ret

; Send the 5x7 glyph that HL points to to the LCD, at its current position.
; After having called this, the LCD's position will have advanced by one
; position
lcdSendGlyph:
	push	af
	push	bc
	push	hl

	; For the purpose of this program, we only write on the first line.
	; We can assume that we always start at row 0.
	xor	a
	call	lcdSetRow

	ld	b, 7
.loop:
	ld	a, (hl)
	inc	hl
	call	lcdWait
	out	(LCD_PORT_DATA), a
	djnz	.loop

	; Now that we've sent our 7 rows of pixels, let's go in "Y-increment"
	; mode to let the LCD increase by one column after we've sent our 8th
	; line, which is blank (padding).
	ld	a, LCD_CMD_YINC
	call	lcdWait
	out	(LCD_PORT_CMD), a

	; send blank line
	xor	a
	call	lcdWait
	out	(LCD_PORT_DATA), a

	; go back in X-increment mode
	ld	a, LCD_CMD_XINC
	call	lcdWait
	out	(LCD_PORT_CMD), a

	pop	hl
	pop	bc
	pop	af
	ret

lcdPutC:
	push	hl
	call	fntGet
	jr	nz, .end
	call	lcdSendGlyph
.end:
	pop	hl
	ret
