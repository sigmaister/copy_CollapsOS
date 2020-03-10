; *** Const ***
; Base of the Return Stack
.equ	RS_ADDR		0xf000
; Number of bytes we keep as a padding between HERE and the scratchpad
.equ	PADDING		0x20
; Max length of dict entry names
.equ	NAMELEN		7
; Offset of the code link relative to the beginning of the word
.equ	CODELINK_OFFSET	NAMELEN+3

; *** Variables ***
.equ	INITIAL_SP	FORTH_RAMSTART
.equ	CURRENT		@+2
.equ	HERE		@+2
.equ	INPUTPOS	@+2
; Buffer where we compile the current input line. Same size as STDIO_BUFSIZE.
.equ	COMPBUF		@+2
.equ	FORTH_RAMEND	@+0x40

; *** Code ***
forthMain:
	; STACK OVERFLOW PROTECTION:
	; To avoid having to check for stack underflow after each pop operation
	; (which can end up being prohibitive in terms of costs), we give
	; ourselves a nice 6 bytes buffer. 6 bytes because we seldom have words
	; requiring more than 3 items from the stack. Then, at each "exit" call
	; we check for stack underflow.
	push	af \ push af \ push af
	ld	(INITIAL_SP), sp
	ld	hl, LATEST
	ld	(CURRENT), hl
	ld	hl, FORTH_RAMEND
	ld	(HERE), hl
forthRdLine:
	ld	hl, msgOk
	call	printstr
	call	printcrlf
	call	stdioReadLine
	ld	(INPUTPOS), hl
forthInterpret:
	ld	ix, RS_ADDR-2		; -2 because we inc-before-push
	ld	iy, INTERPRET
	jp	executeCodeLink
msgOk:
	.db	" ok", 0
