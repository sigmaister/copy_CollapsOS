; *** Variables ***
; Value of `SP` when basic was first invoked. This is where SP is going back to
; on restarts.
.equ	BAS_INITSP	BAS_RAMSTART
; **Pointer** to current line number
.equ	BAS_PCURLN	@+2
.equ	BAS_RAMEND	@+2

; *** Code ***
basStart:
	ld	(BAS_INITSP), sp
	xor	a
	ld	hl, .welcome
	call	printstr
	call	printcrlf
	ld	hl, .welcome+2		; points to a zero word
	ld	(BAS_PCURLN), hl
	jr	basPrompt

.welcome:
	.db "OK", 0, 0

basPrompt:
	ld	hl, .sPrompt
	call	printstr
	call	stdioReadLine
	call	parseDecimal
	jr	z, .number
	call	basDirect
	jr	basPrompt
.number:
	; do nothing for now, we only support direct mode.
	ld	hl, .sNumber
	call	basPrintLn
	jr	basPrompt
.sNumber:
	.db "A number!", 0
.sPrompt:
	.db "> ", 0

basDirect:
	ex	de, hl
	ld	hl, basCmds1
.loop:
	ld	a, 4
	call	strncmp
	jr	z, .found
	ld	a, 6
	call	addHL
	ld	a, (hl)
	cp	0xff
	jr	nz, .loop
	ld	hl, .sUnknown
	jr	basPrintLn

.found:
	inc	hl \ inc hl \ inc hl \ inc hl
	call	intoHL
	jp	(hl)

.sUnknown:
	.db	"Unknown command", 0

basPrintLn:
	call	printcrlf
	call	printstr
	jp	printcrlf

; *** Commands ***
basBYE:
	ld	hl, .sBye
	call	basPrintLn
	; To quit the loop, let's return the stack to its initial value and
	; then return.
	xor	a
	ld	sp, (BAS_INITSP)
	ret
.sBye:
	.db	"Goodbye!", 0

; direct only
basCmds1:
	.db	"bye", 0
	.dw	basBYE
; statements
basCmds2:
	.db	0xff	; end of table
