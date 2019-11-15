; Last check:
; Kernel size: 0x619
; Kernel RAM usage: 0x66
; Shell size: 0x411
; Shell RAM usage: 0x11

.inc "blkdev.h"
.inc "fs.h"
.inc "err.h"
.inc "ascii.h"
.equ	RAMSTART	0x4000
; 0x100 - 0x66 gives us a nice space for the stack.
.equ	KERNEL_RAMEND	0x4100
.equ	SHELL_CODE	0x0700
.equ	STDIO_PORT	0x00
.equ	FS_DATA_PORT	0x01
.equ	FS_ADDR_PORT	0x02

	jp	init

; *** JUMP TABLE ***
	jp	strncmp
	jp	upcase
	jp	findchar
	jp	blkSelPtr
	jp	blkSel
	jp	blkSet
	jp	blkSeek
	jp	blkTell
	jp	blkGetB
	jp	blkPutB
	jp	fsFindFN
	jp	fsOpen
	jp	fsGetB
	jp	fsPutB
	jp	fsSetSize
	jp	fsOn
	jp	fsIter
	jp	fsAlloc
	jp	fsDel
	jp	fsHandle
	jp	printstr
	jp	printnstr
	jp	_blkGetB
	jp	_blkPutB
	jp	_blkSeek
	jp	_blkTell
	jp	printcrlf
	jp	stdioGetC
	jp	stdioPutC
	jp	stdioReadLine

.inc "core.asm"
.inc "str.asm"

.equ	BLOCKDEV_RAMSTART	RAMSTART
.equ	BLOCKDEV_COUNT		4
.inc "blockdev.asm"
; List of devices
.dw	fsdevGetB, fsdevPutB
.dw	stdoutGetB, stdoutPutB
.dw	stdinGetB, stdinPutB
.dw	mmapGetB, mmapPutB


.equ	MMAP_START	0xe000
.inc "mmap.asm"

.equ	STDIO_RAMSTART	BLOCKDEV_RAMEND
.equ	STDIO_GETC	emulGetC
.equ	STDIO_PUTC	emulPutC
.inc "stdio.asm"

.equ	FS_RAMSTART	STDIO_RAMEND
.equ	FS_HANDLE_COUNT	2
.inc "fs.asm"

init:
	di
	; setup stack
	ld	sp, KERNEL_RAMEND
	call	fsInit
	ld	a, 0	; select fsdev
	ld	de, BLOCKDEV_SEL
	call	blkSel
	call	fsOn
	call	SHELL_CODE

emulGetC:
	; Blocks until a char is returned
	in	a, (STDIO_PORT)
	cp	a		; ensure Z
	ret

emulPutC:
	out	(STDIO_PORT), a
	ret

fsdevGetB:
	ld	a, e
	out	(FS_ADDR_PORT), a
	ld	a, h
	out	(FS_ADDR_PORT), a
	ld	a, l
	out	(FS_ADDR_PORT), a
	in	a, (FS_ADDR_PORT)
	or	a
	ret	nz
	in	a, (FS_DATA_PORT)
	cp	a		; ensure Z
	ret

fsdevPutB:
	push	af
	ld	a, e
	out	(FS_ADDR_PORT), a
	ld	a, h
	out	(FS_ADDR_PORT), a
	ld	a, l
	out	(FS_ADDR_PORT), a
	in	a, (FS_ADDR_PORT)
	cp	2		; only A > 1 means error
	jr	nc, .error	; A >= 2
	pop	af
	out	(FS_DATA_PORT), a
	cp	a		; ensure Z
	ret
.error:
	pop	af
	jp	unsetZ		; returns

.equ	STDOUT_HANDLE	FS_HANDLES

stdoutGetB:
	ld	ix, STDOUT_HANDLE
	jp	fsGetB

stdoutPutB:
	ld	ix, STDOUT_HANDLE
	jp	fsPutB

.equ	STDIN_HANDLE	FS_HANDLES+FS_HANDLE_SIZE

stdinGetB:
	ld	ix, STDIN_HANDLE
	jp	fsGetB

stdinPutB:
	ld	ix, STDIN_HANDLE
	jp	fsPutB

.fill SHELL_CODE-$
.bin "shell.bin"
