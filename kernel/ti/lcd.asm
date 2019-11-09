; lcd
;
; Implement PutC on TI-84+ (for now)'s LCD screen.
;
; The screen is 96x64 pixels. The 64 rows are addressed directly with CMD_ROW
; but columns are addressed in chunks of 6 or 8 bits (there are two modes).
;
; In 6-bit mode, there are 16 visible columns. In 8-bit mode, there are 12.
;
; Note that "X-increment" and "Y-increment" work in the opposite way than what
; most people expect. Y moves left and right, X moves up and down.
;
; *** Z-Offset ***
;
; This LCD has a "Z-Offset" parameter, allowing to offset rows on the
; screen however we wish. This is handy because it allows us to scroll more
; efficiently. Instead of having to copy the LCD ram around at each linefeed
; (or instead of having to maintain an in-memory buffer), we can use this
; feature.
;
; The Z-Offet goes upwards, with wrapping. For example, if we have an 8 pixels
; high line at row 0 and if our offset is 8, that line will go up 8 pixels,
; wrapping itself to the bottom of the screen.
;
; The principle is this: The active line is always the bottom one. Therefore,
; when active row is 0, Z is FNT_HEIGHT+1, when row is 1, Z is (FNT_HEIGHT+1)*2,
; When row is 8, Z is 0.
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
; Current column
.equ	LCD_CURCOL	@+1
.equ	LCD_RAMEND	@+1

; *** Code ***
lcdInit:
	; Initialize variables
	xor	a
	ld	(LCD_CURROW), a
	ld	(LCD_CURCOL), a

	; Clear screen
	call	lcdClrScr

	; We begin with a Z offset of FNT_HEIGHT+1
	ld	a, LCD_CMD_ZOFFSET+FNT_HEIGHT+1
	call	lcdCmd

	; Enable the LCD
	ld	a, LCD_CMD_ENABLE
	call	lcdCmd

	; Hack to get LCD to work. According to WikiTI, we're not sure why TIOS
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
	ld	a, (LCD_CURCOL)
	call	lcdSetCol

	; let's increase (and wrap) col now
	inc	a
	ld	(LCD_CURCOL), a
	cp	16
	jr	nz, .skip
	call	lcdLinefeed
.skip:
	ld	b, FNT_HEIGHT
.loop:
	ld	a, (hl)
	inc	hl
	call	lcdData
	djnz	.loop

	pop	hl
	pop	bc
	pop	af
	ret

; Changes the current line and go back to leftmost column
lcdLinefeed:
	push	af
	ld	a, (LCD_CURROW)
	call	.addFntH
	ld	(LCD_CURROW), a
	call	lcdClrLn
	; Now, lets set Z offset which is CURROW+FNT_HEIGHT+1
	call	.addFntH
	add	a, LCD_CMD_ZOFFSET
	call	lcdCmd
	xor	a
	ld	(LCD_CURCOL), a
	pop	af
	ret
.addFntH:
	add	a, FNT_HEIGHT+1
	cp	64
	ret	c		; A < 64? no wrap
	; we have to wrap around
	xor	a
	ret

; Clears B rows starting at row A
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
