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
	call	varInit
	call	bufInit
	xor	a
	ld	hl, .welcome
	call	printstr
	call	printcrlf
	ld	hl, .welcome+2		; points to a zero word
	ld	(BAS_PCURLN), hl
	jr	basLoop

.welcome:
	.db "OK", 0, 0

basLoop:
	ld	hl, .sPrompt
	call	printstr
	call	stdioReadLine
	call	printcrlf
	call	parseDecimal
	jr	z, .number
	ld	de, basCmds1
	call	basCallCmd
	jr	z, basLoop
	; Error
	call	basERR
	jr	basLoop
.number:
	push	ix \ pop de
	call	toWS
	call	rdWS
	call	bufAdd
	jp	nz, basERR
	jr	basLoop
.sPrompt:
	.db "> ", 0

; Call command in (HL) after having looked for it in cmd table in (DE).
; If found, jump to it. If not found, unset Z. We expect commands to set Z
; on success. Therefore, when calling basCallCmd results in NZ, we're not sure
; where the error come from, but well...
; Before being evaluated, (HL) is copied in BAS_SCRATCHPAD because some
; evaluation routines (such as parseExpr) mutate the string it evaluates.
; TODO: straighten this situation up. Mutating a string like this breaks
; expectations.
basCallCmd:
	push	de	; --> lvl 1
	ld	de, BAS_SCRATCHPAD
	call	strcpy
	ex	de, hl	; HL now points to scratchpad
	pop	de	; <-- lvl 1
	; let's see if it's a variable assignment.
	call	varTryAssign
	ret	z	; Done!
	; Second, get cmd length
	call	fnWSIdx
	cp	7
	jp	nc, unsetZ	; Too long, can't possibly fit anything.
	; A contains whitespace IDX, save it in B
	ld	b, a
	ex	de, hl
	inc	hl \ inc hl
.loop:
	ld	a, b		; whitespace IDX
	call	strncmp
	jr	z, .found
	ld	a, 8
	call	addHL
	ld	a, (hl)
	cp	0xff
	jr	nz, .loop
	; not found
	jp	unsetZ
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


basPrintLn:
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
;
; Commands are expected to set Z on success.
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
	cp	a		; ensure Z
	ret


basRUN:
	call	bufFirst
	ret	nz
.loop:
	call	bufStr
	ld	de, basCmds2
	push	ix		; --> lvl 1
	call	basCallCmd
	pop	ix		; <-- lvl 1
	jp	nz, .err
	call	bufNext
	jr	z, .loop
	cp	a		; ensure Z
	ret
.err:
	; Print line number, then return NZ (which will print ERR)
	ld	e, (ix)
	ld	d, (ix+1)
	ld	hl, BAS_SCRATCHPAD
	call	fmtDecimal
	call	printstr
	ld	a, ' '
	call	stdioPutC
	jp	unsetZ

.runline:

basPRINT:
	call	parseExpr
	ret	nz
	push	ix \ pop de
	ld	hl, BAS_SCRATCHPAD
	call	fmtDecimal
	cp	a		; ensure Z
	jp	basPrintLn

; direct only
basCmds1:
	.dw	basBYE
	.db	"bye", 0, 0, 0
	.dw	basLIST
	.db	"list", 0, 0
	.dw	basRUN
	.db	"run", 0, 0, 0
; statements
basCmds2:
	.dw	basPRINT
	.db	"print", 0
	.db	0xff, 0xff, 0xff	; end of table
