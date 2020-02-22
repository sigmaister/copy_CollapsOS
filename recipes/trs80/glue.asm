; RAMSTART is a label at the end of the file
.equ	RAMEND		0xcfff
; Address of the *CL driver. Same as in recv.asm
.equ	COM_DRV_ADDR	0x0238

; Free memory in TRSDOS starts at 0x3000
.org	0x3000
	jp	init

.inc "err.h"
.inc "blkdev.h"
.inc "ascii.h"
.inc "core.asm"
.inc "str.asm"

.inc "trs80/kbd.asm"
.inc "trs80/vid.asm"
.equ	FLOPPY_RAMSTART	RAMSTART
.inc "trs80/floppy.asm"

.equ	BLOCKDEV_RAMSTART	FLOPPY_RAMEND
.equ	BLOCKDEV_COUNT		1
.inc "blockdev.asm"
; List of devices
.dw	floppyGetB, floppyPutB

.equ	STDIO_RAMSTART	BLOCKDEV_RAMEND
.equ	STDIO_GETC	trs80GetC
.equ	STDIO_PUTC	trs80PutC
.inc "stdio.asm"

; The TRS-80 generates a double line feed if we give it both CR and LF.
.equ	printcrlf	printcr

; *** BASIC ***

; RAM space used in different routines for short term processing.
.equ	SCRATCHPAD_SIZE	STDIO_BUFSIZE
.equ	SCRATCHPAD	STDIO_RAMEND
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
.inc "basic/blk.asm"
.inc "basic/floppy.asm"
.equ	BAS_RAMSTART	BUF_RAMEND
.inc "basic/main.asm"

init:
	ld	sp, RAMEND
	call	floppyInit
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
	ld	hl, .cmds
	jp	basFindCmd

.cmds:
	.db	"recv", 0
	.dw	recvCmd
	.db	0xff		; end of table

RAMSTART:
