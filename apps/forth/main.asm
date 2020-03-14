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
; Pointer to the next free byte in dict. During compilation of input text, this
; temporarily points to the next free byte in COMPBUF.
.equ	HERE		@+2
; Used to hold HERE while we temporarily point it to COMPBUF
.equ	OLDHERE		@+2
; Interpreter pointer. See Execution model comment below.
.equ	IP		@+2
; Pointer to where we currently are in the interpretation of the current line.
.equ	INPUTPOS	@+2
; Buffer where we compile the current input line. Same size as STDIO_BUFSIZE.
.equ	COMPBUF		@+2
.equ	FORTH_RAMEND	@+0x40

; (HERE) usually starts at RAMEND, but in certain situations, such as in stage0,
; (HERE) will begin at a strategic place.
.equ	HERE_INITIAL	FORTH_RAMEND

; EXECUTION MODEL
; After having read a line through stdioReadLine, we want to interpret it. As
; a general rule, we go like this:
;
; 1. read single word from line
; 2. compile word to atom
; 3. if immediate, execute atom
; 4. goto 1 until we exhaust words
; 5. Execute compiled atom list as if it was a regular compiledWord.
;
; Because the Parameter Stack uses SP, we can't just go around calling routines:
; This messes with the PS. This is why we almost always jump (unless our call
; doesn't involve Forth words in any way).
;
; This presents a challenge for our interpret loop because step 4, "goto 1"
; isn't obvious. To be able to do that, we must push a "return routine" to the
; Return Stack before step 3.
;
; HERE and IMMEDIATE: When compiling in step 2, we spit compiled atoms in
; (HERE) to simplify "," semantic in Forth (spitting, in all cases, is done in
; (HERE)). However, suring input line compilation, it isn't like during ":", we
; aren't creating a new entry.
;
; Compiling and executing from (HERE) would be dangerous because an
; entry-creation word, during runtime, could end up overwriting the atom list
; we're executing. This is why we have this list in COMPBUF.
;
; During IMMEDIATE mode, (HERE) is temporarily set to COMPBUF, and when we're
; done, we restore (HERE) for runtime. This way, everyone is happy.
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
	; We're about to compile the line and possibly execute IMMEDIATE words.
	; Let's save current (HERE) and temporarily set it to COMPBUF.
	ld	hl, (HERE)
	ld	(OLDHERE), hl
	ld	hl, COMPBUF
	ld	(HERE), hl
	ld	hl, .retRef
	ld	(IP), hl
	ld	hl, INTERPRET
	push	hl
	jp	EXECUTE+2
.retRef:
	.dw	$+2
	.dw	forthExecLine

forthExecLine:
	ld	de, QUIT
	ld	hl, (HERE)
	call	DEinHL
	ld	(HERE), hl
	; Compilation done, let's restore (HERE) and execute!
	ld	hl, (OLDHERE)
	ld	(HERE), hl
	ld	iy, COMPBUF
	; before we execute, let's play with our RS a bit: compiledWord is
	; going to push (IP) on the RS, but we don't expect our compiled words
	; to ever return: it ends with QUIT. Let's set (IP) to ABORTREF and
	; IX to RS_ADDR-2 so that compiledWord re-pushes our safety net.
	ld	hl, ABORTREF
	ld	(IP), hl
	ld	ix, RS_ADDR-2
	jp	compiledWord

; (we don't have RECURSE here. Calling interpret makes us needlessly use our
; RS stack, but it can take it, can't it? )
; WORD COMPILE IN> @ C@ (to check if null) SKIP? (skip if not null) EXIT INTERPRET
	.db	0b10		; UNWORD
INTERPRET:
	.dw	compiledWord
	.dw	WORD
	.dw	COMPILE
	.dw	INP
	.dw	FETCH
	.dw	CFETCH
	.dw	CSKIP
	.dw	EXIT
	.dw	INTERPRET
	.dw	EXIT

msgOk:
	.db	" ok", 0
