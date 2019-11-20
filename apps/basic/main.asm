; *** Constants ***
.equ	BAS_SCRATCHPAD_SIZE	0x20
; *** Variables ***
; Value of `SP` when basic was first invoked. This is where SP is going back to
; on restarts.
.equ	BAS_INITSP	BAS_RAMSTART
; **Pointer** to current line number
.equ	BAS_PCURLN	@+2
.equ	BAS_SCRATCHPAD	@+2
.equ	BAS_RAMEND	@+BAS_SCRATCHPAD_SIZE

; *** Code ***
basStart:
	ld	(BAS_INITSP), sp
	call	bufInit
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
	push	ix \ pop de
	call	toWS
	call	rdWS
	call	bufAdd
	jp	nz, basERR
	call	printcrlf
	jr	basPrompt
.sPrompt:
	.db "> ", 0

basDirect:
	; First, get cmd length
	call	fnWSIdx
	cp	7
	jr	nc, .unknown	; Too long, can't possibly fit anything.
	; A contains whitespace IDX, save it in B
	ld	b, a
	ex	de, hl
	ld	hl, basCmds1+2
.loop:
	ld	a, b		; whitespace IDX
	call	strncmp
	jr	z, .found
	ld	a, 8
	call	addHL
	ld	a, (hl)
	cp	0xff
	jr	nz, .loop
.unknown:
	ld	hl, .sUnknown
	jr	basPrintLn

.found:
	dec	hl \ dec hl
	call	intoHL
	push	hl \ pop ix
	; Bring back command string from DE to HL
	ex	de, hl
	ld	a, b	; cmd's length
	call	addHL
	call	rdWS
	jp	(ix)

.sUnknown:
	.db	"Unknown command", 0

basPrintLn:
	call	printcrlf
	call	printstr
	jp	printcrlf

basERR:
	ld	hl, .sErr
	jr	basPrintLn
.sErr:
	.db	"ERR", 0

; *** Commands ***
; A command receives its argument through (HL), which is already placed to
; either:
; 1 - the end of the string if the command has no arg.
; 2 - the beginning of the arg, with whitespace properly skipped.
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

basLIST:
	call	printcrlf
	call	bufFirst
	ret	nz
.loop:
	ld	e, (ix)
	ld	d, (ix+1)
	ld	hl, BAS_SCRATCHPAD
	call	fmtDecimal
	call	printstr
	ld	a, ' '
	call	stdioPutC
	call	bufStr
	call	printstr
	call	printcrlf
	call	bufNext
	jr	z, .loop
	ret


basPRINT:
	call	parseExpr
	jp	nz, basERR
	push	ix \ pop de
	ld	hl, BAS_SCRATCHPAD
	call	fmtDecimal
	jp	basPrintLn

; direct only
basCmds1:
	.dw	basBYE
	.db	"bye", 0, 0, 0
	.dw	basLIST
	.db	"list", 0, 0
; statements
basCmds2:
	.dw	basPRINT
	.db	"print", 0
	.db	0xff, 0xff, 0xff	; end of table
