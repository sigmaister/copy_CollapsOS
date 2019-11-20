; *** Consts ***
; maximum number of lines (line number maximum, however, is always 0xffff)
.equ	BUF_MAXLINES	0x100
; Size of the string pool
.equ	BUF_POOLSIZE	0x1000

; *** Variables ***
; A pointer to the first free line
.equ	BUF_LFREE	BUF_RAMSTART
; A pointer to the first free byte in the pool
.equ	BUF_PFREE	@+2
; The line index. Each record consists of 4 bytes: 2 for line number,
; 2 for pointer to string in pool. Kept in order of line numbers.
.equ	BUF_LINES	@+2
; The line pool. A list of null terminated strings. BUF_LINES records point
; to those strings.
.equ	BUF_POOL	@+BUF_MAXLINES*4
.equ	BUF_RAMEND	@+BUF_POOLSIZE

bufInit:
	ld	hl, BUF_LINES
	ld	(BUF_LFREE), hl
	ld	hl, BUF_POOL
	ld	(BUF_PFREE), hl
	ret

; Add line at (HL) with line number DE to the buffer. The string at (HL) should
; not contain the line number prefix or the whitespace between the line number
; and the comment.
; Note that an empty string is *not* an error. It will be saved as a line.
; Z for success.
; Error conditions are:
; * not enough space in the pool
; * not enough space in the line index
bufAdd:
	exx			; preserve HL and DE
	; First step: do we have index space?
	ld	hl, (BUF_LFREE)
	ld	de, BUF_POOL
	or	a		; reset carry
	sbc	hl, de
	exx			; restore
	; no carry? HL >= BUF_POOL, error. Z already unset
	ret	nc
	; Second step: see if we're within the pool's bounds
	call	strlen
	inc	a		; strlen doesn't include line termination
	exx			; preserve HL and DE
	ld	hl, (BUF_PFREE)
	call	addHL
	ld	de, BUF_RAMEND
	sbc	hl, de
	exx			; restore
	; no carry? HL >= BUF_RAMEND, error. Z already unset
	ret	nc
	; We have enough space.
	; Third step: set line index data
	push	de	; --> lvl 1
	push	hl	; --> lvl 2
	ld	hl, (BUF_LFREE)
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	ld	de, (BUF_PFREE)
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	ld	(BUF_LFREE), hl
	pop	hl \ push hl	; <-- lvl 2, restore and preserve

	; Fourth step: copy string to pool
	ld	de, (BUF_PFREE)
	call	strcpyM
	ld	(BUF_PFREE), de
	pop	hl	; <-- lvl 2
	pop	de	; <-- lvl 1
	ret

; Set IX to point to the beginning of the pool.
; Z set if (IX) is a valid line, unset if the pool is empty.
bufFirst:
	ld	ix, BUF_LINES
	jp	bufEOF

; Given a valid line record in IX, move IX to the next line.
; This routine doesn't check that IX is valid. Ensure IX validity before
; calling.
bufNext:
	inc	ix \ inc ix \ inc ix \ inc ix
	jp	bufEOF

; Returns whether line index at IX is past the end of file, that is,
; whether IX == (BUF_LFREE)
; Z is set when not EOF, unset when EOF.
bufEOF:
	push	hl
	push	de
	push	ix \ pop hl
	ld	de, (BUF_LFREE)
	sbc	hl, de
	jr	z, .empty
	cp	a		; ensure Z
.end:
	pop	de
	pop	hl
	ret
.empty:
	call	unsetZ
	jr	.end

; Given a line index in (IX), set HL to its associated string pointer.
bufStr:
	ld	l, (ix+2)
	ld	h, (ix+3)
	ret
