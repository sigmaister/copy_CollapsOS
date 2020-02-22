; floppy
;
; Implement a block device around a TRS-80 floppy. It uses SVCs supplied by
; TRS-DOS to do so.
;
; *** Floppy buffers ***
;
; The dual-buffer system is exactly the same as in the "sdc" module. See
; comments there.
;
; *** Consts ***
; Number of sector per cylinder. We only support single density for now.
.equ	FLOPPY_SEC_PER_CYL	10
.equ	FLOPPY_MAX_CYL		40
.equ	FLOPPY_BLKSIZE		256

; *** Variables ***
; This is a pointer to the currently selected buffer. This points to the BUFSEC
; part, that is, two bytes before actual content begins.
.equ	FLOPPY_BUFPTR		FLOPPY_RAMSTART
; Sector number currently in FLOPPY_BUF1. Little endian like any other z80 word.
.equ	FLOPPY_BUFSEC1		@+2
; Whether the buffer has been written to. 0 means clean. 1 means dirty.
.equ	FLOPPY_BUFDIRTY1	@+2
; The contents of the buffer.
.equ	FLOPPY_BUF1		@+1

; second buffer has the same structure as the first.
.equ	FLOPPY_BUFSEC2		@+FLOPPY_BLKSIZE
.equ	FLOPPY_BUFDIRTY2	@+2
.equ	FLOPPY_BUF2		@+1
.equ	FLOPPY_RAMEND		@+FLOPPY_BLKSIZE

; *** Code ***
floppyInit:
	; Make sure that both buffers are flagged as invalid
	ld	a, 0xff
	ld	(FLOPPY_BUFSEC1), a
	ld	(FLOPPY_BUFSEC2), a
	ret

; Read sector index specified in E and cylinder specified in D and place the
; contents in buffer pointed to by (FLOPPY_BUFPTR).
; If the operation is a success, updates buffer's sector to the value of DE.
; Z on success
floppyRdSec:
	ld	a, e
	cp	FLOPPY_SEC_PER_CYL
	jp	nc, unsetZ
	ld	a, d
	cp	FLOPPY_MAX_CYL
	jp	nc, unsetZ

	push	bc
	push	hl

	ld	a, 0x28		; @DCSTAT
	ld	c, 1		; hardcoded to drive :1 for now
	rst	0x28
	jr	nz, .end

	ld	hl, (FLOPPY_BUFPTR)	; HL --> active buffer's sector
	ld	(hl), e		; sector
	inc	hl
	ld	(hl), d		; cylinder
	inc	hl		; dirty
	xor	a
	ld	(hl), a		; clear dirty
	inc	hl		; data
	ld	a, 0x31		; @RDSEC
	rst	0x28		; sets Z appropriately
.end:
	pop	hl
	pop	bc
	ret

; not implemented yet.
floppyWrSec:
	xor	a
	ret

; Considering the first 15 bits of EHL, select the most appropriate of our two
; buffers and, if necessary, sync that buffer with the floppy. If the selected
; buffer doesn't have the same sector as what EHL asks, load that buffer from
; the floppy.
; If the dirty flag is set, we write the content of the in-memory buffer to the
; floppy before we read a new sector.
; Returns Z on success, NZ on error
floppySync:
	push	de
	; Given a 24-bit address in EHL, extracts the 16-bit sector from it and
	; place it in DE, following cylinder and sector rules.
	; EH is our sector index, L is our offset within the sector.

	ld	d, e		; cylinder
	ld	a, h		; sector
	; Let's process D first. Because our maximum number of sectors is 400
	; (40 * 10), D can only be either 0 or 1. If it's 1, we set D to 25 and
	; add 6 to A
	inc	d \ dec d
	jr	z, .loop1	; skip
	ld	d, 25
	add	a, 6
.loop1:
	cp	FLOPPY_SEC_PER_CYL
	jr	c, .loop1end
	sub	FLOPPY_SEC_PER_CYL
	inc	d
	jr	.loop1
.loop1end:
	ld	e, a			; write final sector in E
	; Let's first see if our first buffer has our sector
	ld	a, (FLOPPY_BUFSEC1)	; sector
	cp	e
	jr	nz, .notBuf1
	ld	a, (FLOPPY_BUFSEC1+1)	; cylinder
	cp	d
	jr	z, .buf1Ok

.notBuf1:
	; Ok, let's check for buf2 then
	ld	a, (FLOPPY_BUFSEC2)	; sector
	cp	e
	jr	nz, .notBuf2
	ld	a, (FLOPPY_BUFSEC2+1)	; cylinder
	cp	d
	jr	z, .buf2Ok

.notBuf2:
	; None of our two buffers have the sector we need, we'll need to load
	; a new one.

	; We select our buffer depending on which is dirty. If both are on the
	; same status of dirtiness, we pick any (the first in our case). If one
	; of them is dirty, we pick the clean one.
	push	de			; --> lvl 1
	ld	de, FLOPPY_BUFSEC1
	ld	a, (FLOPPY_BUFDIRTY1)
	or	a			; is buf1 dirty?
	jr	z, .ready		; no? good, that's our buffer
	; yes? then buf2 is our buffer.
	ld	de, FLOPPY_BUFSEC2

.ready:
	; At this point, DE points to one of our two buffers, the good one.
	; Let's save it to FLOPPY_BUFPTR
	ld	(FLOPPY_BUFPTR), de

	pop	de			; <-- lvl 1

	; We have to read a new sector, but first, let's write the current one
	; if needed.
	call	floppyWrSec
	jr	nz, .end	; error
	; Let's read our new sector in DE
	call	floppyRdSec
	jr	.end

.buf1Ok:
	ld	de, FLOPPY_BUFSEC1
	ld	(FLOPPY_BUFPTR), de
	; Z already set
	jr	.end

.buf2Ok:
	ld	de, FLOPPY_BUFSEC2
	ld	(FLOPPY_BUFPTR), de
	; Z already set
	; to .end
.end:
	pop	de
	ret

; *** blkdev routines ***

; Make HL point to its proper place in FLOPPY_BUF.
; EHL currently is a 24-bit offset to read in the floppy. E=high byte,
; HL=low word. Load the proper sector in memory and make HL point to the
; correct data in the memory buffer.
_floppyPlaceBuf:
	call	floppySync
	ret	nz		; error
	; At this point, we have the proper buffer in place and synced in
	; (FLOPPY_BUFPTR). Only L is important
	ld	a, l
	ld	hl, (FLOPPY_BUFPTR)
	inc	hl		; sector MSB
	inc	hl		; dirty flag
	inc	hl		; contents
	; DE is now placed on the data part of the active buffer and all we need
	; is to increase DE by L.
	call	addHL
	; Now, HL points exactly at the right byte in the active buffer.
	xor	a		; ensure Z
	ret

floppyGetB:
	push	hl
	call	_floppyPlaceBuf
	jr	nz, .end	; NZ already set

	; This is it!
	ld	a, (hl)
	cp	a		; ensure Z
.end:
	pop	hl
	ret

floppyPutB:
	push	hl
	push	af		; --> lvl 1. let's remember the char we put,
				; _floppyPlaceBuf destroys A.
	call	_floppyPlaceBuf
	jr	nz, .error

	; HL points to our dest. Recall A and write
	pop	af		; <-- lvl 1
	ld	(hl), a

	; Now, let's set the dirty flag
	ld	a, 1
	ld	hl, (FLOPPY_BUFPTR)
	inc	hl		; sector MSB
	inc	hl		; point to dirty flag
	ld	(hl), a		; set dirty flag
	xor	a		; ensure Z
	jr	.end
.error:
	; preserve error code
	ex	af, af'
	pop	af		; <-- lvl 1
	ex	af, af'
	call	unsetZ
.end:
	pop	hl
	ret
