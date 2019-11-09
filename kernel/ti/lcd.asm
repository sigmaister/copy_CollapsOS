; lcd
;
; Implement PutC on TI-84+ (for now)'s LCD screen.
;
; Note that "X-increment" and "Y-increment" work in the opposite way than what
; most people expect. Y moves left and right, X moves up and down.
; 
; *** Requirements ***
; fnt/mgm
;
; *** Constants ***
.equ	LCD_PORT_CMD		0x10
.equ	LCD_PORT_DATA		0x11

.equ	LCD_CMD_6BIT		0x00
.equ	LCD_CMD_8BIT		0x01
.equ	LCD_CMD_DISABLE		0x02
.equ	LCD_CMD_ENABLE		0x03
.equ	LCD_CMD_XINC		0x05
.equ	LCD_CMD_YINC		0x07
.equ	LCD_CMD_COL		0x20
.equ	LCD_CMD_ZOFFSET		0x40
.equ	LCD_CMD_ROW		0x80
.equ	LCD_CMD_CONTRAST	0xc0

; *** Variables ***
; Current row being written on. In terms of pixels, not of glyphs. During a
; linefeed, this increases by FNT_HEIGHT+1.
.equ	LCD_CURROW	LCD_RAMSTART
.equ	LCD_RAMEND	@+1

; *** Code ***
lcdInit:
	; Initialize variables
	xor	a
	ld	(LCD_CURROW), a

	; Clear screen
	call	lcdClrScr

	; Enable the LCD
	ld	a, LCD_CMD_ENABLE
	call	lcdCmd

	; Hack to get LCD to work. According to WikiTI, we're to sure why TIOS
	; sends these, but it sends it, and it is required to make the LCD
	; work. So...
	ld	a, 0x17
	call	lcdCmd
	ld	a, 0x0b
	call	lcdCmd

	; Set some usable contrast
	ld	a, LCD_CMD_CONTRAST+0x34
	call	lcdCmd

	; Enable 6-bit mode.
	ld	a, LCD_CMD_6BIT
	call	lcdCmd

	; Enable X-increment mode
	ld	a, LCD_CMD_XINC
	call	lcdCmd

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

; Send cmd A to LCD
lcdCmd:
	out	(LCD_PORT_CMD), a
	jr	lcdWait
	
; Send data A to LCD
lcdData:
	out	(LCD_PORT_DATA), a
	jr	lcdWait

; Turn LCD off
lcdOff:
	push	af
	ld	a, LCD_CMD_DISABLE
	call	lcdCmd
	out	(LCD_PORT_CMD), a
	pop	af
	ret

; Set LCD's current column to A
lcdSetCol:
	push	af
	; The col index specified in A is compounded with LCD_CMD_COL
	add	a, LCD_CMD_COL
	call	lcdCmd
	pop	af
	ret

; Set LCD's current row to A
lcdSetRow:
	push	af
	; The col index specified in A is compounded with LCD_CMD_COL
	add	a, LCD_CMD_ROW
	call	lcdCmd
	pop	af
	ret

; Send the 5x7 glyph that HL points to to the LCD, at its current position.
; After having called this, the LCD's position will have advanced by one
; position
lcdSendGlyph:
	push	af
	push	bc
	push	hl

	ld	a, (LCD_CURROW)
	call	lcdSetRow

	ld	b, 7
.loop:
	ld	a, (hl)
	inc	hl
	call	lcdData
	djnz	.loop

	; Now that we've sent our 7 rows of pixels, let's go in "Y-increment"
	; mode to let the LCD increase by one column after we've sent our 8th
	; line, which is blank (padding).
	ld	a, LCD_CMD_YINC
	call	lcdCmd

	; send blank line
	xor	a
	call	lcdData

	; go back in X-increment mode
	ld	a, LCD_CMD_XINC
	call	lcdCmd

	pop	hl
	pop	bc
	pop	af
	ret

; Changes the current line and go back to leftmost column
lcdLinefeed:
	push	af
	ld	a, (LCD_CURROW)
	add	a, FNT_HEIGHT+1
	ld	(LCD_CURROW), a
	xor	a
	call	lcdSetCol
	pop	af
	ret

; Clears B rows starting at row A
; The LCD will then be set back at row A, column 0
; B is not preserved by this routine
lcdClrX:
	push	af
	call	lcdSetRow
	ld	a, LCD_CMD_8BIT
	call	lcdCmd
.outer:
	push	bc		; --> lvl 1
	ld	b, 11
	ld	a, LCD_CMD_YINC
	call	lcdCmd
	xor	a
	call	lcdSetCol
.inner:
	call	lcdData
	djnz	.inner
	ld	a, LCD_CMD_XINC
	call	lcdCmd
	xor	a
	call	lcdData
	pop	bc		; <-- lvl 1
	djnz	.outer
	ld	a, LCD_CMD_6BIT
	call	lcdCmd
	pop	af
	ret

lcdClrLn:
	push	bc
	ld	b, FNT_HEIGHT+1
	call	lcdClrX
	pop	bc
	ret

lcdClrScr:
	push	bc
	ld	b, 64
	call	lcdClrX
	pop	bc
	ret

lcdPutC:
	cp	ASCII_LF
	jp	z, lcdLinefeed
	push	hl
	call	fntGet
	jr	nz, .end
	call	lcdSendGlyph
.end:
	pop	hl
	ret
