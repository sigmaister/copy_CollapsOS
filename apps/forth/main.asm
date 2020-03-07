; *** Const ***
; Base of the Return Stack
.equ	RS_ADDR		0xf000
; Number of bytes we keep as a padding between HERE and the scratchpad
.equ	PADDING		0x20
; Offset of the code link relative to the beginning of the word
.equ	CODELINK_OFFSET	10
; When set, the interpret should quit
.equ	FLAG_ENDPGM	1

; *** Variables ***
.equ	INITIAL_SP	FORTH_RAMSTART
.equ	CURRENT		@+2
.equ	HERE		@+2
.equ	INPUTPOS	@+2
.equ	FLAGS		@+2
.equ	FORTH_RAMEND	@+1

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
	; not quitting, loop
	jr	forthLoop
.endpgm:
	ld	sp, (INITIAL_SP)
	xor	a
	ret

forthMain:
	xor	a
	ld	(FLAGS), a
	ld	(INITIAL_SP), sp
	ld	hl, DOT		; last entry in hardcoded dict
	ld	(CURRENT), hl
	ld	hl, FORTH_RAMEND
	ld	(HERE), hl
forthLoop:
	ld	ix, RS_ADDR
	ld	iy, MAIN
	jp	executeCodeLink
