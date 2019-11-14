; 8K of onboard RAM
.equ	RAMSTART	0xc000
.equ	USER_RAMSTART	0xc200
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
	jp	parseArgs
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
.inc "core.asm"
.inc "str.asm"
.inc "parse.asm"

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

.equ	SHELL_RAMSTART	FS_RAMEND
.equ	SHELL_EXTRA_CMD_COUNT 10
.inc "shell.asm"
.dw	edCmd, zasmCmd, fnewCmd, fdelCmd, fopnCmd, flsCmd, blkBselCmd
.dw	blkSeekCmd, blkLoadCmd, blkSaveCmd

.inc "blockdev_cmds.asm"
.inc "fs_cmds.asm"

.equ	PGM_RAMSTART		SHELL_RAMEND
.equ	PGM_CODEADDR		USER_RAMSTART
.inc "pgm.asm"

.out	PGM_RAMEND

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

	call	shellInit
	ld	hl, pgmShellHook
	ld	(SHELL_CMDHOOK), hl
	jp	shellLoop

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

edCmd:
	.db	"ed", 0, 0, 0b1001, 0, 0
	push	hl \ pop ix
	ld	l, (ix)
	ld	h, (ix+1)
	jp	0x1900

zasmCmd:
	.db	"zasm", 0b1001, 0, 0
	push	hl \ pop ix
	ld	l, (ix)
	ld	h, (ix+1)
	jp	0x1d00

; last time I checked, PC at this point was 0x183c. Let's give us a nice margin
; for the start of ed.
.fill 0x1900-$
.bin "ed.bin"

; Last check: 0x1c4e
.fill 0x1d00-$
.bin "zasm.bin"

.fill 0x7ff0-$
.db "TMR SEGA", 0x00, 0x00, 0xfb, 0x68, 0x00, 0x00, 0x00, 0x4c


