; grid - abstraction for grid-like video output
;
; Collapse OS doesn't support curses-like interfaces: too complicated. However,
; in cases where output don't have to go through a serial interface before
; being displayed, we have usually have access to a grid-like interface.
;
; Direct access to this kind of interface allow us to build an abstraction layer
; that is very much alike curses but is much simpler underneath. This unit is
; this abstraction.
;
; The principle is simple: we have a cell grid of X columns by Y rows and we
; can access those cells by their (X, Y) address. In addition to this, we have
; the concept of an active cursor, which will be indicated visually if possible.
;
; This module provides PutC and GetC routines, suitable for plugging into stdio.
; PutC, for obvious reasons, GetC, for less obvious reasons: We need to wrap
; GetC because we need to update the cursor before calling actual GetC, but
; also, because we need to know when a bulk update ends.
;
; *** Defines ***
;
; GRID_COLS: Number of columns in the grid
; GRID_ROWS: Number of rows in the grid
; GRID_SETCELL: Pointer to routine that sets cell at row D and column E with
;               character in A. If C is nonzero, this cell must be displayed,
;               if possible, as the cursor. This routine is never called with
;		A < 0x20.
; GRID_GETC: Routine that gridGetC will wrap around.
;
; *** Consts ***
.equ	GRID_SIZE	GRID_COLS*GRID_ROWS

; *** Variables ***
; Cursor's column
.equ	GRID_CURX	GRID_RAMSTART
; Cursor's row
.equ	GRID_CURY	@+1
; Whether we scrolled recently. We don't refresh the screen immediately when
; scrolling in case we have many lines being spit at once (refreshing the
; display is then very slow). Instead, we wait until the next gridGetC call
.equ	GRID_SCROLLED	@+1
; Grid's in-memory buffer of the contents on screen. Because we always push to
; display right after a change, this is almost always going to be a correct
; representation of on-screen display.
; The buffer is organized as a rows of columns. The cell at row Y and column X
; is at GRID_BUF+(Y*GRID_COLS)+X.
.equ	GRID_BUF	@+1
.equ	GRID_RAMEND	@+GRID_SIZE

; *** Code ***

gridInit:
	xor	a
	ld	b, GRID_RAMEND-GRID_RAMEND
	ld	hl, GRID_RAMSTART
	jp	fill

; Place HL at row D and column E in the buffer
; Destroys A
_gridPlaceCell:
	ld	hl, GRID_BUF
	ld	a, d
	or	a
	jr	z, .setcol
	push	de		; --> lvl 1
	ld	de, GRID_COLS
.loop:
	add	hl, de
	dec	a
	jr	nz, .loop
	pop	de		; <-- lvl 1
.setcol:
	; We're at the proper row, now let's advance to cell
	ld	a, e
	jp	addHL

; Ensure that A >= 0x20
_gridAdjustA:
	cp	0x20
	ret	nc
	ld	a, 0x20
	ret

; Push row D in the buffer onto the screen.
gridPushRow:
	push	af
	push	bc
	push	de
	push	hl
	; Cursor off
	ld	c, 0
	ld	e, c
	call	_gridPlaceCell
	ld	b, GRID_COLS
.loop:
	ld	a, (hl)
	call	_gridAdjustA
	; A, C, D and E have proper values
	call	GRID_SETCELL
	inc	hl
	inc	e
	djnz	.loop

	pop	hl
	pop	de
	pop	bc
	pop	af
	ret

; Clear row D and push contents to screen
gridClrRow:
	push	af
	push	bc
	push	de
	push	hl
	ld	e, 0
	call	_gridPlaceCell
	ld	a, ' '
	ld	b, GRID_COLS
	call	fill
	call	gridPushRow
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret

gridPushScr:
	push	de
	ld	d, GRID_ROWS-1
.loop:
	call	gridPushRow
	dec	d
	jp	p, .loop
	pop	de
	ret

; Set character under cursor to A. C is passed to GRID_SETCELL as-is.
gridSetCur:
	push	de
	push	hl
	push	af		; --> lvl 1
	ld	a, (GRID_CURY)
	ld	d, a
	ld	a, (GRID_CURX)
	ld	e, a
	call	_gridPlaceCell
	pop	af \ push af	; <--> lvl 1
	ld	(hl), a
	call	_gridAdjustA
	call	GRID_SETCELL
	pop	af		; <-- lvl 1
	pop	hl
	pop	de
	ret

; Call gridSetCur with C = 1.
gridSetCurH:
	push	bc
	ld	c, 1
	call	gridSetCur
	pop	bc
	ret

; Call gridSetCur with C = 0.
gridSetCurL:
	push	bc
	ld	c, 0
	call	gridSetCur
	pop	bc
	ret

; Clear character under cursor
gridClrCur:
	push	af
	ld	a, ' '
	call	gridSetCurL
	pop	af
	ret

gridLF:
	call	gridClrCur
	push	de
	push	af
	ld	a, (GRID_CURY)
	; increase A
	inc	a
	cp	GRID_ROWS
	jr	nz, .noscroll
	; bottom reached, stay on last line and scroll screen
	push	hl
	push	de
	push	bc
	ld	de, GRID_BUF
	ld	hl, GRID_BUF+GRID_COLS
	ld	bc, GRID_SIZE-GRID_COLS
	ldir
	ld	hl, GRID_SCROLLED
	inc	(hl)			; mark as scrolled
	pop	bc
	pop	de
	pop	hl
	dec	a
.noscroll:
	; A has been increased properly
	ld	d, a
	call	gridClrRow
	ld	(GRID_CURY), a
	xor	a
	ld	(GRID_CURX), a
	pop	af
	pop	de
	ret

gridBS:
	call	gridClrCur
	push	af
	ld	a, (GRID_CURX)
	or	a
	jr	z, .lineup
	dec	a
	ld	(GRID_CURX), a
	pop	af
	ret
.lineup:
	; end of line, we need to go up one line. But before we do, are we
	; already at the top?
	ld	a, (GRID_CURY)
	or	a
	jr	z, .end
	dec	a
	ld	(GRID_CURY), a
	ld	a, GRID_COLS-1
	ld	(GRID_CURX), a
.end:
	pop	af
	ret

gridPutC:
	cp	LF
	jr	z, gridLF
	cp	BS
	jr	z, gridBS
	cp	' '
	ret	c		; ignore unhandled control characters

	call	gridSetCurL
	push	af		; --> lvl 1
	; Move cursor
	ld	a, (GRID_CURX)
	cp	GRID_COLS-1
	jr	z, .incline
	; We just need to increase X
	inc	a
	ld	(GRID_CURX), a
	pop	af		; <-- lvl 1
	ret
.incline:
	; increase line and start anew
	call	gridLF
	pop	af		; <-- lvl 1
	ret

gridGetC:
	ld	a, (GRID_SCROLLED)
	or	a
	jr	z, .nopush
	; We've scrolled recently, update screen
	xor	a
	ld	(GRID_SCROLLED), a
	call	gridPushScr
.nopush:
	ld	a, ' '
	call	gridSetCurH
	jp	GRID_GETC
