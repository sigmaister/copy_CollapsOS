; *** Variables ***
; Value of `SP` when basic was first invoked. This is where SP is going back to
; on restarts.
.equ	BAS_INITSP	BAS_RAMSTART
; Pointer to next line to run. If nonzero, it means that the next line is
; the first of the list. This is used by GOTO to indicate where to jump next.
; Important note: this is **not** a line number, it's a pointer to a line index
; in buffer. If it's not zero, its a valid pointer.
.equ	BAS_PNEXTLN	@+2
.equ	BAS_RAMEND	@+2

; *** Code ***
basStart:
	ld	(BAS_INITSP), sp
	call	varInit
	call	bufInit
	xor	a
	ld	(BAS_PNEXTLN), a
	ld	(BAS_PNEXTLN+1), a
	ld	hl, .welcome
	call	printstr
	call	printcrlf
	jr	basLoop

.welcome:
	.db "OK", 0

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
	call	toSep
	call	rdSep
	call	bufAdd
	jp	nz, basERR
	jr	basLoop
.sPrompt:
	.db "> ", 0

; Call command in (HL) after having looked for it in cmd table in (DE).
; If found, jump to it. If not found, unset Z. We expect commands to set Z
; on success. Therefore, when calling basCallCmd results in NZ, we're not sure
; where the error come from, but well...
basCallCmd:
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
	call	rdSep
	jp	(ix)

basERR:
	ld	hl, .sErr
	call	printstr
	jp	printcrlf
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
	call	printstr
	call	printcrlf
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
	ld	hl, SCRATCHPAD
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
	call	.maybeGOTO
	jr	nz, .loop	; IX already set
	call	bufFirst
	ret	nz
.loop:
	call	bufStr
	ld	de, basCmds2
	push	ix		; --> lvl 1
	call	basCallCmd
	pop	ix		; <-- lvl 1
	jp	nz, .err
	call	.maybeGOTO
	jr	nz, .loop	; IX already set
	call	bufNext
	jr	z, .loop
	cp	a		; ensure Z
	ret
.err:
	; Print line number, then return NZ (which will print ERR)
	ld	e, (ix)
	ld	d, (ix+1)
	ld	hl, SCRATCHPAD
	call	fmtDecimal
	call	printstr
	ld	a, ' '
	call	stdioPutC
	jp	unsetZ

; This returns the opposite Z result as the one we usually see: Z is set if
; we **don't** goto, unset if we do. If we do, IX is properly set.
.maybeGOTO:
	ld	de, (BAS_PNEXTLN)
	ld	a, d
	or	e
	ret	z
	; we goto
	push	de \ pop ix
	; we need to reset our goto marker
	ld	de, 0
	ld	(BAS_PNEXTLN), de
	ret

basPRINT:
	ld	de, SCRATCHPAD
	call	rdWord
	push	hl		; --> lvl 1
	ex	de, hl
	call	parseExpr
	ret	nz
	push	ix \ pop de
	ld	hl, SCRATCHPAD
	call	fmtDecimal
	call	printstr
	pop	hl		; <-- lvl 1
	; Do we have another arg?
	call	rdSep
	jr	z, .another
	; no, we can stop here
	cp	a		; ensure Z
	jp	printcrlf
.another:
	; Before we jump to basPRINT, let's print a space
	ld	a, ' '
	call	stdioPutC
	jr	basPRINT

basGOTO:
	ld	de, SCRATCHPAD
	call	rdWord
	ex	de, hl
	call	parseExpr
	ret	nz
	push	ix \ pop de
	call	bufFind
	jr	nz, .notFound
	push	ix \ pop de
	; Z already set
	jr	.end
.notFound:
	ld	de, 0
	; Z already unset
.end:
	ld	(BAS_PNEXTLN), de
	ret

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
	.dw	basGOTO
	.db	"goto", 0, 0
	.db	0xff, 0xff, 0xff	; end of table
