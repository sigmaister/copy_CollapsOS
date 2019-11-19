; *** Consts ***
.equ	BUF_POOLSIZE	0x1000

; *** Variables ***
; A pointer to free space in the pool.
.equ	BUF_FREE	BUF_RAMSTART
; The line pool. Each line consists of a two bytes binary number followed by
; a one byte length followed by the command string, which doesn't include its
; line number (example "10 print 123" becomes "print 123"), but which is null
; terminated. The one byte length includes null termination. For example, if
; we have a line record starting at 0x1000 and that its length field indicates
; 0x42, this means that the next line starts at 0x1045 (0x42+2+1).
.equ	BUF_POOL	@+2
.equ	BUF_RAMEND	@+BUF_POOLSIZE

bufInit:
	ld	hl, BUF_POOL
	ld	(BUF_FREE), hl
	ret

; Add line at (HL) with line number DE to the pool. The string at (HL) should
; not contain the line number prefix or the whitespace between the line number
; and the comment.
; Note that an empty string is *not* an error. It will be saved as a line.
; Don't send strings that are more than 0xfe in length. It won't work well.
; Z for success.
; The only error condition that is handled is when there is not enough space
; left in the pool to add a string of (HL)'s size. In that case, nothing will
; be done and Z will be unset.
;
; DESTROYED REGISTER: DE. Too much pushpopping around to keep it. Not worth it.
bufAdd:
	push	hl	; --> lvl 1
	push	de	; --> lvl 2
	; First step: see if we're within the pool's bounds
	call	strlen
	inc	a		; strlen doesn't include line termination
	ld	hl, (BUF_FREE)
	call	addHL
	; add overhead (3b)
	inc	hl \ inc hl \ inc hl
	ld	de, BUF_RAMEND
	sbc	hl, de
	; no carry? HL >= BUF_RAMEND, error. Z already unset
	jr	nc, .error
	; We have enough space, proceed
	ld	hl, (BUF_FREE)
	pop	de		; <-- lvl 2
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	; A has been untouched since that strlen call. Let's use it as-is.
	ld	(hl), a
	inc	hl	; HL now points to dest for our string.
	ex	de, hl
	pop	hl \ push hl	; <--> lvl 1. recall orig, but also preserve
	call	strcpyM
	; Copying done. Let's update the free zone marker.
	ld	(BUF_FREE), de
	xor	a		; set Z
	pop	hl		; <-- lvl 1
	ret
.error:
	pop	de
	pop	hl
	ret

; Set IX to point to the first valid line we have in the pool.
; Error if the pool is empty.
; Z for success.
bufFirst:
	ld	a, (BUF_POOL+2)
	or	a
	jp	z, unsetZ
	ld	ix, BUF_POOL
	xor	a		; set Z
	ret

; Given a valid line record in IX, move IX to the next valid line.
; This routine doesn't check that IX is valid. Ensure IX validity before
; calling. This routine also doesn't check that the next line is within the
; bounds of the pool because this check is done during bufAdd.
; The only possible error is if there is no next line.
; Z for success.
bufNext:
	push	de		; --> lvl 1
	ld	d, 0
	ld	e, (ix+2)
	add	ix, de
	inc	ix \ inc ix \ inc ix
	pop	de		; <-- lvl 1
	ld	a, (ix+2)
	or	a
	jp	z, unsetZ
	xor	a		; set Z
	ret
