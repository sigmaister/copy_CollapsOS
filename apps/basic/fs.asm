; FS-related basic commands
; *** Variables ***
; Handle of the target file
.equ	BFS_FILE_HDL	BFS_RAMSTART
.equ	BFS_RAMEND	@+FS_HANDLE_SIZE

basFLS:
	ld	iy, .iter
	jp	fsIter
.iter:
	ld	a, FS_META_FNAME_OFFSET
	call	addHL
	call	printstr
	jp	printcrlf


basLDBAS:
	call	fsFindFN
	ret	nz
	call	bufInit
	ld	ix, BFS_FILE_HDL
	call	fsOpen
	ld	hl, 0
	ld	de, SCRATCHPAD
.loop:
	ld	ix, BFS_FILE_HDL
	call	fsGetB
	jr	nz, .loopend
	inc	hl
	or	a		; null? hum, weird. same as LF
	jr	z, .lineend
	cp	LF
	jr	z, .lineend
	ld	(de), a
	inc	de
	jr	.loop
.lineend:
	; We've just finished reading a line, writing each char in the pad.
	; Null terminate it.
	xor	a
	ld	(de), a
	; Ok, line ready
	push	hl		; --> lvl 1. current file position
	ld	hl, SCRATCHPAD
	call	parseDecimal
	jr	nz, .notANumber
	push	ix \ pop de
	call	toSep
	call	rdSep
	call	bufAdd
	pop	hl		; <-- lvl 1
	ret	nz
	ld	de, SCRATCHPAD
	jr	.loop
.notANumber:
	pop	hl		; <-- lvl 1
	ld	de, SCRATCHPAD
	jr	.loop
.loopend:
	cp	a
	ret


basFSCmds:
	.dw	basFLS
	.db	"fls", 0, 0, 0
	.dw	basLDBAS
	.db	"ldbas", 0
	.db	0xff, 0xff, 0xff	; end of table
