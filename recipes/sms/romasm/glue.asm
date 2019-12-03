; TODO: This recipe has not been tested since its conversion to the BASIC shell.
; My PS/2 adapter has been acting up and probably has a loose wire. I need to
; fix it beore I can test this recipe on real hardware.
; But theoretically, it works...

; 8K of onboard RAM
.equ	RAMSTART	0xc000
.equ	USER_CODE	0xd500
; Memory register at the end of RAM. Must not overwrite
.equ	RAMEND		0xddd0

	jp	init

; *** JUMP TABLE ***
	jp	strncmp
	jp	upcase
	jp	findchar
	jp	parseHex
	jp	parseHexPair
	jp	blkSel
	jp	blkSet
	jp	fsFindFN
	jp	fsOpen
	jp	fsGetB
	jp	fsPutB
	jp	fsSetSize
	jp	printstr
	jp	_blkGetB
	jp	_blkPutB
	jp	_blkSeek
	jp	_blkTell
	jp	printcrlf
	jp	stdioPutC
	jp	stdioReadLine

.fill 0x66-$
	retn

.inc "err.h"
.inc "ascii.h"
.inc "blkdev.h"
.inc "fs.h"
.inc "core.asm"
.inc "str.asm"

.inc "sms/kbd.asm"
.equ	KBD_RAMSTART	RAMSTART
.equ	KBD_FETCHKC	smskbdFetchKCB
.inc "kbd.asm"

.equ	VDP_RAMSTART	KBD_RAMEND
.inc "sms/vdp.asm"

.equ	STDIO_RAMSTART	VDP_RAMEND
.equ	STDIO_GETC	kbdGetC
.equ	STDIO_PUTC	vdpPutC
.inc "stdio.asm"

.equ	MMAP_START	0xd700
; 0x180 is to leave some space for the stack
.equ	MMAP_LEN	RAMEND-MMAP_START-0x180
.inc "mmap.asm"

.equ	BLOCKDEV_RAMSTART	STDIO_RAMEND
.equ	BLOCKDEV_COUNT		3
.inc "blockdev.asm"
; List of devices
.dw	mmapGetB, mmapPutB
.dw	f0GetB, f0PutB
.dw	f1GetB, f1PutB


.equ	FS_RAMSTART	BLOCKDEV_RAMEND
.equ	FS_HANDLE_COUNT	2
.inc "fs.asm"

; *** BASIC ***

; RAM space used in different routines for short term processing.
.equ	SCRATCHPAD_SIZE	0x20
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
.equ	BAS_RAMSTART	BFS_RAMEND
.inc "basic/main.asm"

; USER_CODE is set according to this output below.
.out BAS_RAMEND

init:
	di
	im	1

	ld	sp, RAMEND

	; init a FS in mmap
	ld	hl, MMAP_START
	ld	a, 'C'
	ld	(hl), a
	inc	hl
	ld	a, 'F'
	ld	(hl), a
	inc	hl
	ld	a, 'S'
	ld	(hl), a

	call	fsInit
	xor	a
	ld	de, BLOCKDEV_SEL
	call	blkSel
	call	fsOn

	call	kbdInit
	call	vdpInit

	call	basInit
	ld	hl, basFindCmdExtra
	ld	(BAS_FINDHOOK), hl
	jp	basStart

basFindCmdExtra:
	ld	hl, basFSCmds
	call	basFindCmd
	ret	z
	ld	hl, basBLKCmds
	call	basFindCmd
	ret	z
	ld	hl, .mycmds
	call	basFindCmd
	ret	z
	jp	basPgmHook
.mycmds:
	.db "ed", 0
	.dw 0x1e00
	.db "zasm", 0
	.dw 0x2300

f0GetB:
	ld	ix, FS_HANDLES
	jp	fsGetB

f0PutB:
	ld	ix, FS_HANDLES
	jp	fsPutB

f1GetB:
	ld	ix, FS_HANDLES+FS_HANDLE_SIZE
	jp	fsGetB

f1PutB:
	ld	ix, FS_HANDLES+FS_HANDLE_SIZE
	jp	fsPutB

; last time I checked, PC at this point was 0x1df8. Let's give us a nice margin
; for the start of ed.
.fill 0x1e00-$
.bin "ed.bin"

; Last check: 0x22dd
.fill 0x2300-$
.bin "zasm.bin"

.fill 0x7ff0-$
.db "TMR SEGA", 0x00, 0x00, 0xfb, 0x68, 0x00, 0x00, 0x00, 0x4c
