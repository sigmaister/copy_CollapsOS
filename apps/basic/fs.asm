; FS-related basic commands
; *** Variables ***
; Handle of the target file
.equ	BFS_FILE_HDL	BFS_RAMSTART
.equ	BFS_RAMEND	@+FS_HANDLE_SIZE

; Lists filenames in currently active FS
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


basFOPEN:
	call	rdExpr		; file handle index
	ret	nz
	push	ix \ pop de
	ld	a, e
	call	fsHandle
	; DE now points to file handle
	call	rdSep
	; HL now holds the string we look for
	call	fsFindFN
	ret	nz		; not found
	; Found!
	; FS_PTR points to the file we want to open
	push	de \ pop ix	; IX now points to the file handle.
	jp	fsOpen

; Takes one byte block number to allocate as well we one string arg filename
; and allocates a new file in the current fs.
basFNEW:
	call	rdExpr		; file block count
	ret	nz
	call	rdSep		; HL now points to filename
	push	ix \ pop de
	ld	a, e
	out	(42), a
	jp	fsAlloc

; Deletes filename with specified name
basFDEL:
	call	fsFindFN
	ret	nz
	; Found! delete
	jp	fsDel


basPgmHook:
	; Cmd to find is in (DE)
	ex	de, hl
	; (HL) is suitable for a direct fsFindFN call
	call	fsFindFN
	ret	nz
	; We have a file! Let's load it in memory
	ld	ix, BFS_FILE_HDL
	call	fsOpen
	ld	hl, 0		; addr that we read in file handle
	ld	de, USER_CODE	; addr in mem we write to
.loop:
	call	fsGetB		; we use Z at end of loop
	ld	(de), a		; Z preserved
	inc	hl		; Z preserved in 16-bit
	inc	de		; Z preserved in 16-bit
	jr	z, .loop
	; Ready to jump. Return USER_CODE in IX and basCallCmd will take care
	; of setting (HL) to the arg string.
	ld	ix, USER_CODE
	cp	a		; ensure Z
	ret

basFSCmds:
	.dw	basFLS
	.db	"fls", 0, 0, 0
	.dw	basLDBAS
	.db	"ldbas", 0
	.dw	basFOPEN
	.db	"fopen", 0
	.dw	basFNEW
	.db	"fnew", 0, 0
	.dw	basFDEL
	.db	"fdel", 0, 0
	.db	0xff, 0xff, 0xff	; end of table
