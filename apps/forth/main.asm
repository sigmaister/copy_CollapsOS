; *** Const ***
; Base of the Return Stack
.equ	RS_ADDR		0xf000
; Number of bytes we keep as a padding between HERE and the scratchpad
.equ	PADDING		0x20
; Max length of dict entry names
.equ	NAMELEN		8
; Offset of the code link relative to the beginning of the word
.equ	CODELINK_OFFSET	10
; When set, the interpreter should abort parsing of current line and return to
; prompt.
.equ	FLAG_QUITTING	0
; When set, the interpreter should quit
.equ	FLAG_ENDPGM	1

; *** Variables ***
.equ	INITIAL_SP	FORTH_RAMSTART
.equ	CURRENT		@+2
.equ	HERE		@+2
.equ	INPUTPOS	@+2
.equ	FLAGS		@+2
; Buffer where we compile the current input line. Same size as STDIO_BUFSIZE.
.equ	COMPBUF		@+1
.equ	FORTH_RAMEND	@+0x40

; *** Code ***
MAIN:
	.dw compiledWord
	.dw INTERPRET+CODELINK_OFFSET
	.dw CHKEND

; If FLAG_ENDPGM is set, stop the program, else, tweak the RS so that we loop.
CHKEND:
	.dw nativeWord
	ld	hl, FLAGS
	bit	FLAG_ENDPGM, (hl)
	jr	nz, .endpgm
	; not quitting program, are we supposed to continue parsing line?
	ld	hl, FLAGS
	bit	FLAG_QUITTING, (hl)
	jr	nz, forthRdLine
	; Not quitting line either.
	jr	forthInterpret
.endpgm:
	ld	sp, (INITIAL_SP)
	; restore stack
	pop	af \ pop af \ pop af
	xor	a
	ret

forthMain:
	; STACK OVERFLOW PROTECTION:
	; To avoid having to check for stack underflow after each pop operation
	; (which can end up being prohibitive in terms of costs), we give
	; ourselves a nice 6 bytes buffer. 6 bytes because we seldom have words
	; requiring more than 3 items from the stack. Then, at each "exit" call
	; we check for stack underflow.
	push	af \ push af \ push af
	ld	(INITIAL_SP), sp
	ld	hl, DIV		; last entry in hardcoded dict
	ld	(CURRENT), hl
	ld	hl, FORTH_RAMEND
	ld	(HERE), hl
forthRdLine:
	xor	a
	ld	(FLAGS), a
	ld	hl, msgOk
	call	printstr
	call	printcrlf
	call	stdioReadLine
	ld	(INPUTPOS), hl
forthInterpret:
	ld	ix, RS_ADDR
	ld	iy, MAIN
	jp	executeCodeLink
msgOk:
	.db	" ok", 0
