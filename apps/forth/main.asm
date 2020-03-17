; *** Const ***
; Base of the Return Stack
.equ	RS_ADDR		0xf000
; Number of bytes we keep as a padding between HERE and the scratchpad
.equ	PADDING		0x20
; Max length of dict entry names
.equ	NAMELEN		7
; Offset of the code link relative to the beginning of the word
.equ	CODELINK_OFFSET	NAMELEN+3

; Flags for the "flag field" of the word structure
; IMMEDIATE word
.equ	FLAG_IMMED	0
; This wordref is not a regular word (it's not preceeded by a name). It's one
; of the NUMBER, LIT, BRANCH etc. entities.
.equ	FLAG_UNWORD	1

; *** Variables ***
.equ	INITIAL_SP	FORTH_RAMSTART
; wordref of the last entry of the dict.
.equ	CURRENT		@+2
; Pointer to the next free byte in dict.
.equ	HERE		@+2
; Interpreter pointer. See Execution model comment below.
.equ	IP		@+2
; Pointer to where we currently are in the interpretation of the current line.
.equ	INPUTPOS	@+2
; Buffer where we compile the current input line. Same size as STDIO_BUFSIZE.
.equ	FORTH_RAMEND	@+2

; (HERE) usually starts at RAMEND, but in certain situations, such as in stage0,
; (HERE) will begin at a strategic place.
.equ	HERE_INITIAL	FORTH_RAMEND

; EXECUTION MODEL
; After having read a line through stdioReadLine, we want to interpret it. As
; a general rule, we go like this:
;
; 1. read single word from line
; 2. Can we find the word in dict?
; 3. If yes, execute that word, goto 1
; 4. Is it a number?
; 5. If yes, push that number to PS, goto 1
; 6. Error: undefined word.
;
; EXECUTING A WORD
;
; At it's core, executing a word is having the wordref in IY and call
; EXECUTE. Then, we let the word do its things. Some words are special,
; but most of them are of the compiledWord type, and that's their execution that
; we describe here.
;
; First of all, at all time during execution, the Interpreter Pointer (IP)
; points to the wordref we're executing next.
;
; When we execute a compiledWord, the first thing we do is push IP to the Return
; Stack (RS). Therefore, RS' top of stack will contain a wordref to execute
; next, after we EXIT.
;
; At the end of every compiledWord is an EXIT. This pops RS, sets IP to it, and
; continues.

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
	; LATEST is a *indirect* label to the latest entry of the dict. See
	; default at the bottom of dict.asm. This indirection allows us to
	; override latest to a value set in a binary dict compiled separately,
	; for example by the stage0 bin.
	ld	hl, LATEST
	call	intoHL
	ld	(CURRENT), hl
	ld	hl, HERE_INITIAL
	ld	(HERE), hl
	; Set (INPUTPOS) to somewhere where there's a NULL so we consider
	; ourselves EOL.
	ld	(INPUTPOS), hl
	xor	a
	ld	(hl), a
forthRdLine:
	ld	hl, msgOk
	call	printstr
forthRdLineNoOk:
	; Setup return stack. After INTERPRET, we run forthExecLine
	ld	ix, RS_ADDR
	ld	hl, MAINLOOP
	push	hl
	jp	EXECUTE+2

	.db	0b10		; UNWORD
INTERPRET:
	.dw	compiledWord
	.dw	FIND_
	.dw	CSKIP
	.dw	.maybeNum
	; It's a word, execute it
	.dw	EXECUTE
	.dw	EXIT

.maybeNum:
	.dw	compiledWord
	.dw	PARSE
	.dw	R2P		; exit INTERPRET
	.dw	DROP
	.dw	EXIT

	.db	0b10		; UNWORD
MAINLOOP:
	.dw	compiledWord
	.dw	INTERPRET
	.dw	INP
	.dw	FETCH
	.dw	CFETCH
	.dw	CSKIP
	.dw	QUIT
	.dw	MAINLOOP

msgOk:
	.db	" ok", 0
