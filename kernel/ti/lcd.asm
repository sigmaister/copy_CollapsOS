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
; *** 6/8 bit columns and smaller fonts ***
;
; If your glyphs, including padding, are 6 or 8 pixels wide, you're in luck
; because pushing them to the LCD can be done in a very efficient manner.
; Unfortunately, this makes the LCD unsuitable for a Collapse OS shell: 6
; pixels per glyph gives us only 16 characters per line, which is hardly
; usable.
;
; This is why we have this buffering system. How it works is that we're always
; in 8-bit mode and we hold the whole area (8 pixels wide by FNT_HEIGHT high)
; in memory. When we want to put a glyph to screen, we first read the contents
; of that area, then add our new glyph, offsetted and masked, to that buffer,
; then push the buffer back to the LCD. If the glyph is split, move to the next
; area and finish the job.
;
; That being said, it's important to define clearly what CURX and CURY variable
; mean. Those variable keep track of the current position *in pixels*, in both
; axes.
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
.equ	LCD_CMD_XDEC		0x04
.equ	LCD_CMD_XINC		0x05
.equ	LCD_CMD_YDEC		0x06
.equ	LCD_CMD_YINC		0x07
.equ	LCD_CMD_COL		0x20
.equ	LCD_CMD_ZOFFSET		0x40
.equ	LCD_CMD_ROW		0x80
.equ	LCD_CMD_CONTRAST	0xc0

; *** Variables ***
; Current Y position on the LCD, that is, where re're going to spit our next
; glyph.
.equ	LCD_CURY	LCD_RAMSTART
; Current X position
.equ	LCD_CURX	@+1
; two pixel buffers that are 8 pixels wide (1b) by FNT_HEIGHT pixels high.
; This is where we compose our resulting pixels blocks when spitting a glyph.
.equ	LCD_BUF		@+1
.equ	LCD_RAMEND	@+FNT_HEIGHT*2

; *** Code ***
lcdInit:
	; Initialize variables
	xor	a
	ld	(LCD_CURY), a
	ld	(LCD_CURX), a

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

	; Enable 8-bit mode.
	ld	a, LCD_CMD_8BIT
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
lcdDataSet:
	out	(LCD_PORT_DATA), a
	jr	lcdWait

; Get data from LCD into A
lcdDataGet:
	in	a, (LCD_PORT_DATA)
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

; Send the glyph that HL points to to the LCD, at its current position.
; After having called this, the LCD's position will have advanced by one
; position
lcdSendGlyph:
	push	af
	push	bc
	push	hl
	push	ix

	ld	a, (LCD_CURY)
	call	lcdSetRow
	ld	a, (LCD_CURX)
	srl	a \ srl a \ srl a	; div by 8
	call	lcdSetCol

	; First operation: read the LCD memory for the "left" side of the
	; buffer. We assume the right side to always be empty, so we don't
	; read it. After having read each line, compose it with glyph line at
	; HL

	; Before we start, what is our bit offset?
	ld	a, (LCD_CURX)
	and	0b111
	; that's our offset, store it in C
	ld	c, a

	ld	a, LCD_CMD_XINC
	call	lcdCmd
	ld	ix, LCD_BUF
	ld	b, FNT_HEIGHT
	; A dummy read is needed after a movement.
	call	lcdDataGet
.loop1:
	; let's go get that glyph data
	ld	a, (hl)
	ld	(ix), a
	call	.shiftIX
	; now let's go get existing pixel on LCD
	call	lcdDataGet
	; and now let's do some compositing!
	or	(ix)
	ld	(ix), a
	inc	hl
	inc	ix
	djnz	.loop1

	; Buffer set! now let's send it.
	ld	a, (LCD_CURY)
	call	lcdSetRow

	ld	hl, LCD_BUF
	ld	b, FNT_HEIGHT
.loop2:
	ld	a, (hl)
	call	lcdDataSet
	inc	hl
	djnz	.loop2

	; And finally, let's send the "right side" of the buffer
	ld	a, (LCD_CURY)
	call	lcdSetRow
	ld	a, (LCD_CURX)
	srl	a \ srl a \ srl a	; div by 8
	inc	a
	call	lcdSetCol

	ld	hl, LCD_BUF+FNT_HEIGHT
	ld	b, FNT_HEIGHT
.loop3:
	ld	a, (hl)
	call	lcdDataSet
	inc	hl
	djnz	.loop3

	; Increase column and wrap if necessary
	ld	a, (LCD_CURX)
	add	a, FNT_WIDTH+1
	ld	(LCD_CURX), a
	cp	96-FNT_WIDTH
	jr	c, .skip	; A < 96-FNT_WIDTH
	call	lcdLinefeed
.skip:
	pop	ix
	pop	hl
	pop	bc
	pop	af
	ret
; Shift glyph in (IX) to the right C times, sending carry into (IX+FNT_HEIGHT)
.shiftIX:
	dec	c \ inc c
	ret	z		; zero? nothing to do
	push	bc		; --> lvl 1
	xor	a
	ld	b, a
	ld	a, (ix)
	; TODO: support SRL (IX) and RR (IX) in zasm
.shiftLoop:
	srl	a
	rr	b
	dec	c
	jr	nz, .shiftLoop
	ld	(ix), a
	ld	a, b
	ld	(ix+FNT_HEIGHT), a
	pop	bc		; <-- lvl 1
	ret

; Changes the current line and go back to leftmost column
lcdLinefeed:
	push	af
	ld	a, (LCD_CURY)
	call	.addFntH
	ld	(LCD_CURY), a
	call	lcdClrLn
	; Now, lets set Z offset which is CURROW+FNT_HEIGHT+1
	call	.addFntH
	add	a, LCD_CMD_ZOFFSET
	call	lcdCmd
	xor	a
	ld	(LCD_CURX), a
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
.outer:
	push	bc		; --> lvl 1
	ld	b, 11
	ld	a, LCD_CMD_YINC
	call	lcdCmd
	xor	a
	call	lcdSetCol
.inner:
	call	lcdDataSet
	djnz	.inner
	ld	a, LCD_CMD_XINC
	call	lcdCmd
	xor	a
	call	lcdDataSet
	pop	bc		; <-- lvl 1
	djnz	.outer
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
	cp	ASCII_BS
	jr	z, .bs
	push	hl
	call	fntGet
	jr	nz, .end
	call	lcdSendGlyph
.end:
	pop	hl
	ret
.bs:
	ld	a, (LCD_CURX)
	or	a
	ret	z	; going back one line is too complicated.
			; not implemented yet
	sub	FNT_WIDTH+1
	ld	(LCD_CURX), a
	ret
