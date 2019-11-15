; Glue code for the emulated environment
.equ RAMSTART		0x4000
.equ USER_CODE		0x4800
.equ STDIO_PORT		0x00
.equ STDIN_SEEK		0x01
.equ FS_DATA_PORT	0x02
.equ FS_SEEK_PORT	0x03
.equ STDERR_PORT	0x04

jp     init    ; 3 bytes
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
jp	parseArgs
jp	_blkGetB
jp	_blkPutB
jp	_blkSeek
jp	_blkTell
jp	printstr

.inc "core.asm"
.inc "str.asm"
.inc "err.h"
.inc "ascii.h"
.inc "parse.asm"
.equ	BLOCKDEV_RAMSTART	RAMSTART
.equ	BLOCKDEV_COUNT		3
.inc "blockdev.asm"
; List of devices
.dw	emulGetB, unsetZ
.dw	unsetZ, emulPutB
.dw	fsdevGetB, fsdevPutB

.equ	STDIO_RAMSTART	BLOCKDEV_RAMEND
.equ	STDIO_GETC	noop
.equ	STDIO_PUTC	stderrPutC
.inc "stdio.asm"

.equ	FS_RAMSTART	STDIO_RAMEND
.equ	FS_HANDLE_COUNT	0
.inc "fs.asm"

init:
	di
	ld	hl, 0xffff
	ld	sp, hl
	ld	a, 2	; select fsdev
	ld	de, BLOCKDEV_SEL
	call	blkSel
	call	fsOn
	; There's a special understanding between zasm.c and this unit: The
	; addresses 0xff00 and 0xff01 contain the two ascii chars to send to
	; zasm as the 3rd argument.
	ld	a, (0xff00)
	ld	(.zasmArgs+4), a
	ld	a, (0xff01)
	ld	(.zasmArgs+5), a
	ld	hl, .zasmArgs
	call	USER_CODE
	; signal the emulator we're done
	halt

.zasmArgs:
	.db	"0 1 XX", 0

; *** I/O ***
emulGetB:
	; the STDIN_SEEK port works by poking it twice. First poke is for high
	; byte, second poke is for low one.
	ld	a, h
	out	(STDIN_SEEK), a
	ld	a, l
	out	(STDIN_SEEK), a
	in	a, (STDIO_PORT)
	or	a		; cp 0
	jr	z, .eof
	cp	a		; ensure z
	ret
.eof:
	jp	unsetZ

emulPutB:
	out	(STDIO_PORT), a
	cp	a		; ensure Z
	ret

stderrPutC:
	out	(STDERR_PORT), a
	cp	a		; ensure Z
	ret

fsdevGetB:
	ld	a, e
	out	(FS_SEEK_PORT), a
	ld	a, h
	out	(FS_SEEK_PORT), a
	ld	a, l
	out	(FS_SEEK_PORT), a
	in	a, (FS_SEEK_PORT)
	or	a
	ret	nz
	in	a, (FS_DATA_PORT)
	cp	a		; ensure Z
	ret

fsdevPutB:
	push	af
	ld	a, e
	out	(FS_SEEK_PORT), a
	ld	a, h
	out	(FS_SEEK_PORT), a
	ld	a, l
	out	(FS_SEEK_PORT), a
	in	a, (FS_SEEK_PORT)
	or	a
	jr	nz, .error
	pop	af
	out	(FS_DATA_PORT), a
	cp	a		; ensure Z
	ret
.error:
	pop	af
	jp	unsetZ		; returns

