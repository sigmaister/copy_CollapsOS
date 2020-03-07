; *** Const ***
; Base of the Return Stack
.equ	RS_ADDR		0xf000
; Number of bytes we keep as a padding between HERE and the scratchpad
.equ	PADDING		0x20
; Offset of the code link relative to the beginning of the word
.equ	CODELINK_OFFSET	10

; *** Variables ***
.equ	INITIAL_SP	FORTH_RAMSTART
.equ	CURRENT		@+2
.equ	HERE		@+2
.equ	INPUTPOS	@+2
.equ	FORTH_RAMEND	@+2

; *** Code ***
MAIN:
	.dw compiledWord
	.dw INTERPRET+CODELINK_OFFSET
	.dw ENDPGM

ENDPGM:
	.dw nativeWord
	ld	sp, (INITIAL_SP)
	xor	a
	ret

forthMain:
	ld	(INITIAL_SP), sp
	ld	hl, DOT		; last entry in hardcoded dict
	ld	(CURRENT), hl
	ld	hl, FORTH_RAMEND
	ld	(HERE), hl
	ld	ix, RS_ADDR
	ld	iy, MAIN
	jp	executeCodeLink
