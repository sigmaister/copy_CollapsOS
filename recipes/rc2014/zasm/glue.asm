; classic RC2014 setup (8K ROM + 32K RAM) and a stock Serial I/O module
; The RAM module is selected on A15, so it has the range 0x8000-0xffff
.equ	RAMSTART	0x8000
; kernel RAM usage, because of SDC, is a bit high and bring us almost to 0x8500
; We allocate at least 0x200 bytes for the stack, which is why we have this
; threshold.
.equ	RAMEND		0x8700
.equ	PGM_CODEADDR	RAMEND
.equ	ACIA_CTL	0x80	; Control and status. RS off.
.equ	ACIA_IO		0x81	; Transmit. RS on.

	jp	init	; 3 bytes

; *** Jump Table ***
	jp	strncmp
	jp	addDE
	jp	addHL
	jp	upcase
	jp	unsetZ
	jp	intoDE
	jp	intoHL
	jp	writeHLinDE
	jp	findchar
	jp	parseHex
	jp	parseHexPair
	jp	blkSel
	jp	blkSet
	jp	fsFindFN
	jp	fsOpen
	jp	fsGetB
	jp	cpHLDE		; approaching 0x38...

; interrupt hook
.fill	0x38-$
jp	aciaInt

; *** Jump Table (cont.) ***
	jp	parseArgs
	jp	printstr
	jp	_blkGetB
	jp	_blkPutB
	jp	_blkSeek
	jp	_blkTell
	jp	printHexPair
	jp	sdcGetB
	jp	sdcPutB
	jp	blkGetB

.inc "err.h"
.inc "ascii.h"
.inc "core.asm"
.inc "parse.asm"
.equ	ACIA_RAMSTART		RAMSTART
.inc "acia.asm"
.equ	BLOCKDEV_RAMSTART	ACIA_RAMEND
.equ	BLOCKDEV_COUNT		4
.inc "blockdev.asm"
; List of devices
.dw	sdcGetB, sdcPutB
.dw	blk1GetB, blk1PutB
.dw	blk2GetB, blk2PutB
.dw	mmapGetB, mmapPutB


.equ	MMAP_START	0xe000
.inc "mmap.asm"

.equ	STDIO_RAMSTART	BLOCKDEV_RAMEND
.equ	STDIO_GETC	aciaGetC
.equ	STDIO_PUTC	aciaPutC
.inc "stdio.asm"

.equ	FS_RAMSTART	STDIO_RAMEND
.equ	FS_HANDLE_COUNT	2
.inc "fs.asm"

.equ	SHELL_RAMSTART		FS_RAMEND
.equ	SHELL_EXTRA_CMD_COUNT	11
.inc "shell.asm"
.dw	sdcInitializeCmd, sdcFlushCmd
.dw	blkBselCmd, blkSeekCmd, blkLoadCmd, blkSaveCmd
.dw	fsOnCmd, flsCmd, fnewCmd, fdelCmd, fopnCmd

.inc "fs_cmds.asm"
.inc "blockdev_cmds.asm"

.equ	PGM_RAMSTART	SHELL_RAMEND
.inc "pgm.asm"

.equ	SDC_RAMSTART	PGM_RAMEND
.equ	SDC_PORT_CSHIGH	6
.equ	SDC_PORT_CSLOW	5
.equ	SDC_PORT_SPI	4
.inc "sdc.asm"

.out	SDC_RAMEND

init:
	di
	; setup stack
	ld	hl, RAMEND
	ld	sp, hl
	im	1
	call	aciaInit
	call	fsInit
	call	shellInit
	ld	hl, pgmShellHook
	ld	(SHELL_CMDHOOK), hl

	xor	a
	ld	de, BLOCKDEV_SEL
	call	blkSel

	ei
	jp	shellLoop

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
