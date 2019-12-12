.equ	RAMSTART	0x8000
.equ	RAMEND		0xbfff
.equ	PORT_INT_MASK	0x03
.equ	INT_MASK_ON	0x00
.equ	PORT_INT_TRIG	0x04
.equ	INT_TRIG_ON	0x00
.equ	PORT_BANKB	0x07

	jp	boot

.fill 0x18-$
	jp	boot		; reboot

.fill 0x38-$
	jp	handleInterrupt

.fill 0x53-$
	jp boot
; 0x0056
.db 0xFF, 0xA5, 0xFF

.fill 0x64-$

.inc "err.h"
.inc "ascii.h"
.inc "core.asm"
.inc "str.asm"
.equ	FNT_WIDTH	3
.equ	FNT_HEIGHT	5
.inc "fnt/mgm.asm"
.equ	LCD_RAMSTART	RAMSTART
.inc "ti/lcd.asm"
.equ	KBD_RAMSTART	LCD_RAMEND
.inc "ti/kbd.asm"
.equ	STDIO_RAMSTART	KBD_RAMEND
.equ	STDIO_GETC	kbdGetC
.equ	STDIO_PUTC	lcdPutC
.inc "stdio.asm"

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
.equ	BAS_RAMSTART	BUF_RAMEND
.inc "basic/main.asm"

.out BAS_RAMEND
boot:
	di
	ld	sp, RAMEND
	im	1

	; enable ON key interrupt
	in	a, (PORT_INT_MASK)
	set	INT_MASK_ON, a
	out	(PORT_INT_MASK), a
	ld	a, 0x80
	out	(PORT_BANKB), a

	ei

	call	lcdOff

	; sleep until we press ON
	halt

main:
	; Fun fact: if I place this line just above basStart like I would
	; normally do, my TI-84+ refuses to validate the binary. But placed
	; here, validation works fine.
	call	basInit
	call	kbdInit
	call	lcdInit
	xor	a
	call	lcdSetCol
	jp	basStart

handleInterrupt:
	di
	push	af

	; did we push the ON button?
	in	a, (PORT_INT_TRIG)
	bit	INT_TRIG_ON, a
	jp	z, .done		; no? we're done

	; yes? acknowledge and boot
	in	a, (PORT_INT_MASK)
	res	INT_MASK_ON, a		; acknowledge interrupt
	out	(PORT_INT_MASK), a

	pop	af
	ei
	jp	main

.done:
	pop	af
	ei
	reti

FNT_DATA:
.bin "fnt/3x5.bin"
