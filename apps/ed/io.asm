; io - handle ed's I/O

; *** Consts ***
;
; Max length of a line
.equ	IO_MAXLEN	0x7f

; *** Variables ***
; Handle of the target file
.equ	IO_FILE_HDL	IO_RAMSTART
; block device targeting IO_FILE_HDL
.equ	IO_BLK		@+FS_HANDLE_SIZE
; Buffer for lines read from I/O.
.equ	IO_LINE		@+BLOCKDEV_SIZE
.equ	IO_RAMEND	@+IO_MAXLEN+1	; +1 for null
; *** Code ***

; Given a file name in (HL), open that file in (IO_FILE_HDL) and open a blkdev
; on it at (IO_BLK).
ioInit:
	call	fsFindFN
	ret	nz
	ld	ix, IO_FILE_HDL
	call	fsOpen
	ld	de, IO_BLK
	ld	hl, .blkdev
	jp	blkSet
.fsGetB:
	ld	ix, IO_FILE_HDL
	jp	fsGetB
.fsPutB:
	ld	ix, IO_FILE_HDL
	jp	fsPutB
.blkdev:
	.dw	.fsGetB, .fsPutB

ioGetB:
	push	ix
	ld	ix, IO_BLK
	call	_blkGetB
	pop	ix
	ret

ioPutB:
	push	ix
	ld	ix, IO_BLK
	call	_blkPutB
	pop	ix
	ret

ioSeek:
	push	ix
	ld	ix, IO_BLK
	call	_blkSeek
	pop	ix
	ret

ioTell:
	push	ix
	ld	ix, IO_BLK
	call	_blkTell
	pop	ix
	ret

ioSetSize:
	push	ix
	ld	ix, IO_FILE_HDL
	call	fsSetSize
	pop	ix
	ret

; Write string (HL) in current file. Ends line with LF.
ioPutLine:
	push	hl
.loop:
	ld	a, (hl)
	or	a
	jr	z, .loopend		; null, we're finished
	call	ioPutB
	jr	nz, .error
	inc	hl
	jr	.loop
.loopend:
	; Wrote the whole line, write ending LF
	ld	a, 0x0a
	call	ioPutB
	jr	z, .end		; success
	; continue to error
.error:
	call	unsetZ
.end:
	pop	hl
	ret
