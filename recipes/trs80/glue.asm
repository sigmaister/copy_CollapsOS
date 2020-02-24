; RAMSTART is a label at the end of the file
.equ	RAMEND		0xcfff
; Address of the *CL driver. Same as in recv.asm
.equ	COM_DRV_ADDR	0x0238
; in sync with user.h. Last BAS_RAMEND: 0x5705
.equ	USER_CODE	0x5800

; Free memory in TRSDOS starts at 0x3000
.org	0x3000
	jp	init

; The TRS-80 generates a double line feed if we give it both CR and LF.
; Has to be defined before the jump table.
.equ	printcrlf	printcr

; *** Jump Table ***
	jp	strncmp
	jp	upcase
	jp	findchar
	jp	printstr
	jp	printcrlf
	jp	blkSet
	jp	blkSel
	jp	_blkGetB
	jp	_blkPutB
	jp	_blkSeek
	jp	_blkTell
	jp	fsFindFN
	jp	fsOpen
	jp	fsGetB
	jp	fsPutB
	jp	fsSetSize
	jp	stdioPutC
	jp	stdioReadLine

.inc "err.h"
.inc "blkdev.h"
.inc "fs.h"
.inc "ascii.h"
.inc "core.asm"
.inc "str.asm"

.inc "trs80/kbd.asm"
.inc "trs80/vid.asm"
.equ	FLOPPY_RAMSTART	RAMSTART
.inc "trs80/floppy.asm"

.equ	BLOCKDEV_RAMSTART	FLOPPY_RAMEND
.equ	BLOCKDEV_COUNT		3
.inc "blockdev.asm"
; List of devices
.dw	floppyGetB, floppyPutB
.dw	blk1GetB, blk1PutB
.dw	blk2GetB, blk2PutB

.equ	STDIO_RAMSTART	BLOCKDEV_RAMEND
.equ	STDIO_GETC	trs80GetC
.equ	STDIO_PUTC	trs80PutC
.inc "stdio.asm"

.equ	FS_RAMSTART	STDIO_RAMEND
.equ	FS_HANDLE_COUNT	2
.inc "fs.asm"

; *** BASIC ***

; RAM space used in different routines for short term processing.
.equ	SCRATCHPAD_SIZE	STDIO_BUFSIZE
.equ	SCRATCHPAD	FS_RAMEND
.inc "lib/util.asm"
.inc "lib/ari.asm"
.inc "lib/parse.asm"
.inc "lib/fmt.asm"
.equ	EXPR_PARSE	parseLiteralOrVar
.inc "lib/expr.asm"
.inc "basic/util.asm"
.inc "basic/parse.asm"
.inc "basic/tok.asm"
.equ	VAR_RAMSTART	SCRATCHPAD+SCRATCHPAD_SIZE
.inc "basic/var.asm"
.equ	BUF_RAMSTART	VAR_RAMEND
.inc "basic/buf.asm"
.equ	BFS_RAMSTART	BUF_RAMEND
.inc "basic/fs.asm"
.inc "basic/blk.asm"
.inc "basic/floppy.asm"
.equ	BAS_RAMSTART	BFS_RAMEND
.inc "basic/main.asm"

.out	BAS_RAMEND

init:
	ld	sp, RAMEND
	call	floppyInit
	call	fsInit
	call	basInit
	ld	hl, basFindCmdExtra
	ld	(BAS_FINDHOOK), hl

	xor	a
	ld	de, BLOCKDEV_SEL
	call	blkSel

	jp	basStart

printcr:
	push	af
	ld	a, CR
	call	STDIO_PUTC
	pop	af
	ret

; Receive a byte from *cl and put it in A.
; Returns A > 0xff when receiving the last byte
recvCmd:
	xor	a
	ld	(VAR_TBL+1), a	; pre-set MSB
	; put a 0xff mask in B, which will become 0x7f if we receive a 0x20
	ld	b, 0xff
.inner:
	ld	a, 0x03		; @GET
	ld	de, COM_DRV_ADDR
	rst	0x28
	jr	nz, .maybeerror
	or	a
	jr	z, .eof		; Sending a straight NULL ends the comm.
	; @PUT that char back
	ld	c, a
	ld	a, 0x04		; @PUT
	ld	de, COM_DRV_ADDR
	rst	0x28
	ret	nz		; error
	ld	a, c
	cp	0x20
	jr	z, .escapechar
	; not an escape char, good
	and	b		; apply mask
	ld	(VAR_TBL), a
	xor	a		; ensure Z
	ret
.maybeerror:
	; was it an error?
	or	a
	jr	z, .inner	; not an error, just loop
	ret			; error
.escapechar:
	ld	b, 0x7f
	jr	.inner
.eof:
	dec	a		; A = 0xff
	ld	(VAR_TBL+1), a
	xor	a		; ensure Z
	ret

basFindCmdExtra:
	ld	hl, basFloppyCmds
	call	basFindCmd
	ret	z
	ld	hl, basBLKCmds
	call	basFindCmd
	ret	z
	ld	hl, basFSCmds
	call	basFindCmd
	ret	z
	ld	hl, .cmds
	call	basFindCmd
	ret	z
	jp	basPgmHook

.cmds:
	.db	"recv", 0
	.dw	recvCmd
	.db	0xff		; end of table

; *** blkdev 1: file handle 0 ***

blk1GetB:
	ld	ix, FS_HANDLES
	jp	fsGetB

blk1PutB:
	ld	ix, FS_HANDLES
	jp	fsPutB

; *** blkdev 2: file handle 1 ***

blk2GetB:
	ld	ix, FS_HANDLES+FS_HANDLE_SIZE
	jp	fsGetB

blk2PutB:
	ld	ix, FS_HANDLES+FS_HANDLE_SIZE
	jp	fsPutB

RAMSTART:
