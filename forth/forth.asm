; Collapse OS' Forth
;
; Unlike other assembler parts of Collapse OS, this unit is one huge file.
;
; I do this because as Forth takes a bigger place, assembler is bound to take
; less and less place. I am thus consolidating that assembler code in one
; place so that I have a better visibility of what to minimize.
;
; I also want to reduce the featureset of the assembler so that Collapse OS
; self-hosts in a more compact manner. File include is a big part of the
; complexity in zasm. If we can get rid of it, we'll be more compact.

; *** Defines ***
; GETC: address of a GetC routine
; PUTC: address of a PutC routine
;
; Those GetC/PutC routines are hooked through defines and have this API:
;
; GetC: Blocks until a character is read from the device and return that
;       character in A.
;
; PutC: Write character specified in A onto the device.
;
; *** ASCII ***
.equ	BS	0x08
.equ	CR	0x0d
.equ	LF	0x0a
.equ	DEL	0x7f
; *** Const ***
; Base of the Return Stack
.equ	RS_ADDR		0xf000
; Number of bytes we keep as a padding between HERE and the scratchpad
.equ	PADDING		0x20
; Max length of dict entry names
.equ	NAMELEN		7
; Offset of the code link relative to the beginning of the word
.equ	CODELINK_OFFSET	NAMELEN+3
; Buffer where WORD copies its read word to. It's significantly larger than
; NAMELEN, but who knows, in a comment, we might have a very long word...
.equ	WORD_BUFSIZE		0x20
; Allocated space for sysvars (see comment above SYSVCNT)
.equ	SYSV_BUFSIZE		0x10

; Flags for the "flag field" of the word structure
; IMMEDIATE word
.equ	FLAG_IMMED	0

; *** Variables ***
.equ	INITIAL_SP	RAMSTART
; wordref of the last entry of the dict.
.equ	CURRENT		@+2
; Pointer to the next free byte in dict.
.equ	HERE		@+2
; Interpreter pointer. See Execution model comment below.
.equ	IP		@+2
; Global flags
; Bit 0: whether the interpreter is executing a word (as opposed to parsing)
.equ	FLAGS		@+2
; Pointer to the system's number parsing function. It points to then entry that
; had the "(parse)" name at startup. During stage0, it's out builtin PARSE,
; but at stage1, it becomes "(parse)" from core.fs. It can also be changed at
; runtime.
.equ	PARSEPTR	@+2
; Pointer to the word executed by "C<". During stage0, this points to KEY.
; However, KEY ain't very interactive. This is why we implement a readline
; interface in Forth, which we plug in during init. If "(c<)" exists in the
; dict, CINPTR is set to it. Otherwise, we set KEY
.equ	CINPTR		@+2
.equ	WORDBUF		@+2
; Sys Vars are variables with their value living in the system RAM segment. We
; need this mechanisms for core Forth source needing variables. Because core
; Forth source is pre-compiled, it needs to be able to live in ROM, which means
; that we can't compile a regular variable in it. SYSVNXT points to the next
; free space in SYSVBUF. Then, at the word level, it's a regular sysvarWord.
.equ	SYSVNXT		@+WORD_BUFSIZE
.equ	SYSVBUF		@+2
.equ	RAMEND		@+SYSV_BUFSIZE

; (HERE) usually starts at RAMEND, but in certain situations, such as in stage0,
; (HERE) will begin at a strategic place.
.equ	HERE_INITIAL	RAMEND

; EXECUTION MODEL
; After having read a line through readline, we want to interpret it. As
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

; *** Stable ABI ***
; Those jumps below are supposed to stay at these offsets, always. If they
; change bootstrap binaries have to be adjusted because they rely on them.
.fill 0x1a-$
JUMPTBL:
	jp	next
	jp	chkPS

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
	ld	ix, RS_ADDR
	; LATEST is a label to the latest entry of the dict. This can be
	; overridden if a binary dict has been grafted to the end of this
	; binary
	ld	hl, LATEST
	ld	(CURRENT), hl
	ld	hl, HERE_INITIAL
	ld	(HERE), hl
	; Set up PARSEPTR
	ld	hl, PARSE-CODELINK_OFFSET
	call	find
	ld	(PARSEPTR), de
	; Set up CINPTR
	; do we have a C< impl?
	ld	hl, .cinName
	call	find
	jr	z, .skip
	; no? then use KEY
	ld	de, KEY
.skip:
	ld	(CINPTR), de
	; Set up SYSVNXT
	ld	hl, SYSVBUF
	ld	(SYSVNXT), hl
	ld	hl, BEGIN
	push	hl
	jp	EXECUTE+2

.cinName:
	.db	"C<", 0

BEGIN:
	.dw	compiledWord
	.dw	LIT
	.db	"(c<$)", 0
	.dw	FIND_
	.dw	NOT
	.dw	CSKIP
	.dw	EXECUTE
	.dw	INTERPRET

INTERPRET:
	.dw	compiledWord
	; BBR mark
	.dw	WORD
	.dw	FIND_
	.dw	CSKIP
	.dw	FBR
	.db	18
	; It's a word, execute it
	; For now, we only have one flag, let's take advantage of
	; this to keep code simple.
	.dw	ONE			; Bit 0 on
	.dw	FLAGS_
	.dw	STORE
	.dw	EXECUTE
	.dw	ZERO			; Bit 0 off
	.dw	FLAGS_
	.dw	STORE
	.dw	BBR
	.db	25
	; FBR mark, try number
	.dw	PARSEI
	.dw	BBR
	.db	30
	; infinite loop

; *** Collapse OS lib copy ***
; In the process of Forth-ifying Collapse OS, apps will be slowly rewritten to
; Forth and the concept of ASM libs will become obsolete. To facilitate this
; transition, I make, right now, a copy of the routines actually used by Forth's
; native core. This also has the effect of reducing binary size right now and
; give us an idea of Forth's compactness.
; These routines below are copy/paste from apps/lib and stdio.

; copy (HL) into DE, then exchange the two, utilising the optimised HL instructions.
; ld must be done little endian, so least significant byte first.
intoHL:
	push 	de
	ld 	e, (hl)
	inc 	hl
	ld 	d, (hl)
	ex 	de, hl
	pop 	de
	ret

; add the value of A into HL
; affects carry flag according to the 16-bit addition, Z, S and P untouched.
addHL:
	push	de
	ld 	d, 0
	ld	e, a
	add	hl, de
	pop	de
	ret

; Copy string from (HL) in (DE), that is, copy bytes until a null char is
; encountered. The null char is also copied.
; HL and DE point to the char right after the null char.
strcpy:
	ld	a, (hl)
	ld	(de), a
	inc	hl
	inc	de
	or	a
	jr	nz, strcpy
	ret

; Compares strings pointed to by HL and DE until one of them hits its null char.
; If equal, Z is set. If not equal, Z is reset. C is set if HL > DE
strcmp:
	push	hl
	push	de

.loop:
	ld	a, (de)
	cp	(hl)
	jr	nz, .end	; not equal? break early. NZ is carried out
				; to the caller
	or	a		; If our chars are null, stop the cmp
	inc	hl
	inc	de
	jr	nz, .loop	; Z is carried through

.end:
	pop	de
	pop	hl
	; Because we don't call anything else than CP that modify the Z flag,
	; our Z value will be that of the last cp (reset if we broke the loop
	; early, set otherwise)
	ret

; Compares strings pointed to by HL and DE up to NAMELEN count of characters. If
; equal, Z is set. If not equal, Z is reset.
strncmp:
	push	bc
	push	hl
	push	de

	ld	b, NAMELEN
.loop:
	ld	a, (de)
	cp	(hl)
	jr	nz, .end	; not equal? break early. NZ is carried out
				; to the called
	or	a		; If our chars are null, stop the cmp
	jr	z, .end		; The positive result will be carried to the
	                        ; caller
	inc	hl
	inc	de
	djnz	.loop
	; We went through all chars with success, but our current Z flag is
	; unset because of the cp 0. Let's do a dummy CP to set the Z flag.
	cp	a

.end:
	pop	de
	pop	hl
	pop	bc
	; Because we don't call anything else than CP that modify the Z flag,
	; our Z value will be that of the last cp (reset if we broke the loop
	; early, set otherwise)
	ret

; Given a string at (HL), move HL until it points to the end of that string.
strskip:
	push	bc
	ex	af, af'
	xor	a	; look for null char
	ld	b, a
	ld	c, a
	cpir	; advances HL regardless of comparison, so goes one too far
	dec	hl
	ex	af, af'
	pop	bc
	ret

; Borrowed from Tasty Basic by Dimitri Theulings (GPL).
; Divide HL by DE, placing the result in BC and the remainder in HL.
divide:
	push hl		; --> lvl 1
	ld l, h		; divide h by de
	ld h, 0
	call .dv1
	ld b, c		; save result in b
	ld a, l		; (remainder + l) / de
	pop hl		; <-- lvl 1
	ld h, a
.dv1:
	ld c, 0xff	; result in c
.dv2:
	inc c		; dumb routine
	call .subde	; divide using subtract and count
	jr nc, .dv2
	add hl, de
	ret
.subde:
	ld a, l
	sub e		; subtract de from hl
	ld l, a
	ld a, h
	sbc a, d
	ld h, a
	ret


; Parse string at (HL) as a decimal value and return value in DE.
; Reads as many digits as it can and stop when:
; 1 - A non-digit character is read
; 2 - The number overflows from 16-bit
; HL is advanced to the character following the last successfully read char.
; Error conditions are:
; 1 - There wasn't at least one character that could be read.
; 2 - Overflow.
; Sets Z on success, unset on error.

parseDecimal:
	; First char is special: it has to succeed.
	ld	a, (hl)
	; Parse the decimal char at A and extract it's 0-9 numerical value. Put the
	; result in A.
	; On success, the carry flag is reset. On error, it is set.
	add	a, 0xff-'9'	; maps '0'-'9' onto 0xf6-0xff
	sub	0xff-9		; maps to 0-9 and carries if not a digit
	ret	c		; Error. If it's C, it's also going to be NZ
	; During this routine, we switch between HL and its shadow. On one side,
	; we have HL the string pointer, and on the other side, we have HL the
	; numerical result. We also use EXX to preserve BC, saving us a push.
	exx		; HL as a result
	ld	h, 0
	ld	l, a	; load first digit in without multiplying

.loop:
	exx		; HL as a string pointer
	inc hl
	ld a, (hl)
	exx		; HL as a numerical result

	; same as other above
	add	a, 0xff-'9'
	sub	0xff-9
	jr	c, .end

	ld	b, a	; we can now use a for overflow checking
	add	hl, hl	; x2
	sbc	a, a	; a=0 if no overflow, a=0xFF otherwise
	ld	d, h
	ld	e, l		; de is x2
	add	hl, hl	; x4
	rla
	add	hl, hl	; x8
	rla
	add	hl, de	; x10
	rla
	ld	d, a	; a is zero unless there's an overflow
	ld	e, b
	add	hl, de
	adc	a, a	; same as rla except affects Z
	; Did we oveflow?
	jr	z, .loop	; No? continue
	; error, NZ already set
	exx		; HL is now string pointer, restore BC
	; HL points to the char following the last success.
	ret

.end:
	push	hl	; --> lvl 1, result
	exx		; HL as a string pointer, restore BC
	pop	de	; <-- lvl 1, result
	cp	a	; ensure Z
	ret

; *** Support routines ***
; Find the entry corresponding to word where (HL) points to and sets DE to
; point to that entry.
; Z if found, NZ if not.
find:
	push	hl
	push	bc
	ld	de, (CURRENT)
	ld	bc, CODELINK_OFFSET
.inner:
	; DE is a wordref, let's go to beginning of struct
	push	de		; --> lvl 1
	or	a		; clear carry
	ex	de, hl
	sbc	hl, bc
	ex	de, hl		; We're good, DE points to word name
	call	strncmp
	pop	de		; <-- lvl 1, return to wordref
	jr	z, .end		; found
	push	hl		; .prev destroys HL
	call	.prev
	pop	hl
	jr	nz, .inner
	; Z set? end of dict unset Z
	xor	a
	inc	a
.end:
	pop	bc
	pop	hl
	ret

; For DE being a wordref, move DE to the previous wordref.
; Z is set if DE point to 0 (no entry). NZ if not.
.prev:
	dec	de \ dec de \ dec de	; prev field
	push	de			; --> lvl 1
	ex 	de, hl
	call 	intoHL
	ex 	de, hl			; DE contains prev offset
	pop	hl			; <-- lvl 1
	; HL is prev field's addr
	; Is offset zero?
	ld	a, d
	or	e
	ret	z			; no prev entry
	; get absolute addr from offset
	; carry cleared from "or e"
	sbc	hl, de
	ex	de, hl			; result in DE
	ret				; NZ set from SBC

; Checks flags Z and S and sets BC to 0 if Z, 1 if C and -1 otherwise
flagsToBC:
	ld	bc, 0
	ret	z	; equal
	inc	bc
	ret	m	; >
	; <
	dec	bc
	dec	bc
	ret

; Write DE in (HL), advancing HL by 2.
DEinHL:
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	ret

; *** Stack management ***
; The Parameter stack (PS) is maintained by SP and the Return stack (RS) is
; maintained by IX. This allows us to generally use push and pop freely because
; PS is the most frequently used. However, this causes a problem with routine
; calls: because in Forth, the stack isn't balanced within each call, our return
; offset, when placed by a CALL, messes everything up. This is one of the
; reasons why we need stack management routines below. IX always points to RS'
; Top Of Stack (TOS)
;
; This return stack contain "Interpreter pointers", that is a pointer to the
; address of a word, as seen in a compiled list of words.

; Push value HL to RS
pushRS:
	inc	ix
	inc	ix
	ld	(ix), l
	ld	(ix+1), h
	ret

; Pop RS' TOS to HL
popRS:
	ld	l, (ix)
	ld	h, (ix+1)
	dec ix
	dec ix
	ret

popRSIP:
	call	popRS
	ld	(IP), hl
	ret

; Verifies that SP and RS are within bounds. If it's not, call ABORT
chkRS:
	push	ix \ pop hl
	push	de		; --> lvl 1
	ld	de, RS_ADDR
	or	a		; clear carry
	sbc	hl, de
	pop	de		; <-- lvl 1
	jp	c, abortUnderflow
	ret

chkPS:
	push	hl
	ld	hl, (INITIAL_SP)
	; We have the return address for this very call on the stack and
	; protected registers. Let's compensate
	dec	hl \ dec hl
	dec	hl \ dec hl
	or	a		; clear carry
	sbc	hl, sp
	pop	hl
	ret	nc		; (INITIAL_SP) >= SP? good
	jp	abortUnderflow

; *** Dictionary ***
; It's important that this part is at the end of the resulting binary.
; A dictionary entry has this structure:
; - 7b name (zero-padded)
; - 2b prev offset
; - 1b flags (bit 0: IMMEDIATE)
; - 2b code pointer
; - Parameter field (PF)
;
; The prev offset is the number of bytes between the prev field and the
; previous word's code pointer.
;
; The code pointer point to "word routines". These routines expect to be called
; with IY pointing to the PF. They themselves are expected to end by jumping
; to the address at (IP). They will usually do so with "jp next".
;
; That's for "regular" words (words that are part of the dict chain). There are
; also "special words", for example NUMBER, LIT, FBR, that have a slightly
; different structure. They're also a pointer to an executable, but as for the
; other fields, the only one they have is the "flags" field.

; This routine is jumped to at the end of every word. In it, we jump to current
; IP, but we also take care of increasing it my 2 before jumping
next:
	; Before we continue: are stacks within bounds?
	call	chkPS
	call	chkRS
	ld	de, (IP)
	ld	h, d
	ld	l, e
	inc	de \ inc de
	ld	(IP), de
	; HL is an atom list pointer. We need to go into it to have a wordref
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	push	de
	jp	EXECUTE+2


; Execute a word containing native code at its PF address (PFA)
nativeWord:
	jp	(iy)

; Execute a list of atoms, which always end with EXIT.
; IY points to that list. What do we do:
; 1. Push current IP to RS
; 2. Set new IP to the second atom of the list
; 3. Execute the first atom of the list.
compiledWord:
	ld	hl, (IP)
	call	pushRS
	push	iy \ pop hl
	inc	hl
	inc	hl
	ld	(IP), hl
	; IY still is our atom reference...
	ld	l, (iy)
	ld	h, (iy+1)
	push	hl	; argument for EXECUTE
	jp	EXECUTE+2

; Pushes the PFA directly
cellWord:
	push	iy
	jp	next

; Pushes the address in the first word of the PF
sysvarWord:
	ld	l, (iy)
	ld	h, (iy+1)
	push	hl
	jp	next

; The word was spawned from a definition word that has a DOES>. PFA+2 (right
; after the actual cell) is a link to the slot right after that DOES>.
; Therefore, what we need to do push the cell addr like a regular cell, then
; follow the link from the PFA, and then continue as a regular compiledWord.
doesWord:
	push	iy	; like a regular cell
	ld	l, (iy+2)
	ld	h, (iy+3)
	push	hl \ pop iy
	jr	compiledWord

; This is not a word, but a number literal. This works a bit differently than
; others: PF means nothing and the actual number is placed next to the
; numberWord reference in the compiled word list. What we need to do to fetch
; that number is to play with the IP.
numberWord:
	ld	hl, (IP)	; (HL) is out number
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	inc	hl
	ld	(IP), hl	; advance IP by 2
	push	de
	jp	next

NUMBER:
	.dw	numberWord

; Similarly to numberWord, this is not a real word, but a string literal.
; Instead of being followed by a 2 bytes number, it's followed by a
; null-terminated string. When called, puts the string's address on PS
litWord:
	ld	hl, (IP)
	push	hl
	call	strskip
	inc	hl		; after null termination
	ld	(IP), hl
	jp	next

LIT:
	.dw	litWord

; Pop previous IP from Return stack and execute it.
; ( R:I -- )
	.db	"EXIT"
	.fill	3
	.dw	0
	.db	0
EXIT:
	.dw nativeWord
	call	popRSIP
	jp	next

; ( R:I -- )
	.db "QUIT"
	.fill 3
	.dw $-EXIT
	.db 0
QUIT:
	.dw compiledWord
	.dw	ZERO
	.dw	FLAGS_
	.dw	STORE
	.dw	.private
	.dw	INTERPRET

.private:
	.dw	nativeWord
	ld	ix, RS_ADDR
	jp	next

	.db "ABORT"
	.fill 2
	.dw $-QUIT
	.db 0
ABORT:
	.dw	compiledWord
	.dw	.private
	.dw	QUIT

.private:
	.dw	nativeWord
	; Reinitialize PS
	ld	sp, (INITIAL_SP)
	jp	next

abortUnderflow:
	ld	hl, .word
	push	hl
	jp	EXECUTE+2
.word:
	.dw	compiledWord
	.dw	LIT
	.db	"stack underflow", 0
	.dw	PRINT
	.dw	ABORT

	.db "BYE"
	.fill 4
	.dw $-ABORT
	.db 0
BYE:
	.dw nativeWord
	; Goodbye Forth! Before we go, let's restore the stack
	ld	sp, (INITIAL_SP)
	; unwind stack underflow buffer
	pop	af \ pop af \ pop af
	; success
	xor	a
	ret

; ( c -- )
	.db "EMIT"
	.fill 3
	.dw $-BYE
	.db 0
EMIT:
	.dw nativeWord
	pop	hl
	call	chkPS
	ld	a, l
	call	PUTC
	jp	next

	.db	"(print)"
	.dw	$-EMIT
	.db	0
PRINT:
	.dw	nativeWord
	pop	hl
	call	chkPS
.loop:
	ld	a, (hl)		; load character to send
	or	a		; is it zero?
	jp	z, next		; if yes, we're finished
	call	PUTC
	inc	hl
	jr	.loop

; ( c port -- )
	.db "PC!"
	.fill 4
	.dw $-PRINT
	.db 0
PSTORE:
	.dw nativeWord
	pop	bc
	pop	hl
	call	chkPS
	out	(c), l
	jp	next

; ( port -- c )
	.db "PC@"
	.fill 4
	.dw $-PSTORE
	.db 0
PFETCH:
	.dw nativeWord
	pop	bc
	call	chkPS
	ld	h, 0
	in	l, (c)
	push	hl
	jp	next

	.db	"C,"
	.fill	5
	.dw	$-PFETCH
	.db	0
CWR:
	.dw	nativeWord
	pop	de
	call	chkPS
	ld	hl, (HERE)
	ld	(hl), e
	inc	hl
	ld	(HERE), hl
	jp	next


	.db	","
	.fill	6
	.dw	$-CWR
	.db	0
WR:
	.dw	nativeWord
	pop	de
	call	chkPS
	ld	hl, (HERE)
	call	DEinHL
	ld	(HERE), hl
	jp	next


	.db	"ROUTINE"
	.dw	$-WR
	.db	1			; IMMEDIATE
ROUTINE:
	.dw	compiledWord
	.dw	WORD
	.dw	.private
	.dw	EXIT

.private:
	.dw	nativeWord
	pop	hl
	call	chkPS
	ld	a, (hl)
	ld	de, cellWord
	cp	'C'
	jr	z, .end
	ld	de, compiledWord
	cp	'L'
	jr	z, .end
	ld	de, nativeWord
	cp	'V'
	jr	z, .end
	ld	de, JUMPTBL
	cp	'N'
	jr	z, .end
	ld	de, sysvarWord
	cp	'Y'
	jr	z, .end
	ld	de, doesWord
	cp	'D'
	jr	z, .end
	ld	de, LIT
	cp	'S'
	jr	z, .end
	ld	de, NUMBER
	cp	'M'
	jr	z, .end
	ld	de, JUMPTBL+3
	cp	'P'
	jr	nz, .notgood
	; continue to end on match
.end:
	; is our slen 1?
	inc	hl
	ld	a, (hl)
	or	a
	jr	z, .good
.notgood:
	ld	de, 0
.good:
	push	de
	jp	next

; ( addr -- )
	.db "EXECUTE"
	.dw $-ROUTINE
	.db 0
EXECUTE:
	.dw nativeWord
	pop	iy	; is a wordref
	call	chkPS
	ld	l, (iy)
	ld	h, (iy+1)
	; HL points to code pointer
	inc	iy
	inc	iy
	; IY points to PFA
	jp	(hl)	; go!


	.db	";"
	.fill	6
	.dw	$-EXECUTE
	.db	1		; IMMEDIATE
ENDDEF:
	.dw	compiledWord
	.dw	NUMBER
	.dw	EXIT
	.dw	WR
	.dw	R2P		; exit COMPILE
	.dw	DROP
	.dw	R2P		; exit DEFINE
	.dw	DROP
	.dw	EXIT

	.db	":"
	.fill	6
	.dw	$-ENDDEF
	.db	1		; IMMEDIATE
DEFINE:
	.dw	compiledWord
	.dw	ENTRYHEAD
	.dw	NUMBER
	.dw	compiledWord
	.dw	WR
	; BBR branch mark
	.dw	.compile
	.dw	BBR
	.db	4
	; no need for EXIT, ENDDEF takes care of taking us out

.compile:
	.dw	compiledWord
	.dw	WORD
	.dw	FIND_
	.dw	NOT
	.dw	CSKIP
	.dw	FBR
	.db	7
	; Maybe number
	.dw	PARSEI
	.dw	LITN
	.dw	EXIT
	; FBR mark
	.dw	DUP
	.dw	ISIMMED
	.dw	CSKIP
	.dw	FBR
	.db	5
	; is immediate. just execute.
	.dw	EXECUTE
	.dw	EXIT
	; FBR mark
	; just a word, write
	.dw	WR
	.dw	EXIT



	.db "DOES>"
	.fill 2
	.dw $-DEFINE
	.db 0
DOES:
	.dw nativeWord
	; We run this when we're in an entry creation context. Many things we
	; need to do.
	; 1. Change the code link to doesWord
	; 2. Leave 2 bytes for regular cell variable.
	; 3. Write down IP+2 to entry.
	; 3. exit. we're done here.
	ld	hl, (CURRENT)
	ld	de, doesWord
	call	DEinHL
	inc	hl \ inc hl		; cell variable space
	ld	de, (IP)
	call	DEinHL
	ld	(HERE), hl
	jp	EXIT+2


	.db "IMMEDIA"
	.dw $-DOES
	.db 0
IMMEDIATE:
	.dw nativeWord
	ld	hl, (CURRENT)
	dec	hl
	set	FLAG_IMMED, (hl)
	jp	next


	.db	"IMMED?"
	.fill	1
	.dw	$-IMMEDIATE
	.db	0
ISIMMED:
	.dw	nativeWord
	pop	hl
	call	chkPS
	dec	hl
	ld	de, 0
	bit	FLAG_IMMED, (hl)
	jr	z, .notset
	inc	de
.notset:
	push	de
	jp	next

; ( n -- )
	.db	"LITN"
	.fill	3
	.dw	$-ISIMMED
	.db	0
LITN:
	.dw nativeWord
	ld	hl, (HERE)
	ld	de, NUMBER
	call	DEinHL
	pop	de		; number from stack
	call	chkPS
	call	DEinHL
	ld	(HERE), hl
	jp	next

	.db	"SCPY"
	.fill	3
	.dw	$-LITN
	.db	0
SCPY:
	.dw	nativeWord
	pop	hl
	ld	de, (HERE)
	call	strcpy
	ld	(HERE), de
	jp	next


	.db	"(find)"
	.fill	1
	.dw	$-SCPY
	.db	0
FIND_:
	.dw	nativeWord
	pop	hl
	call	find
	jr	z, .found
	; not found
	push	hl
	ld	de, 0
	push	de
	jp	next
.found:
	push	de
	ld	de, 1
	push	de
	jp	next

	.db	"'"
	.fill	6
	.dw	$-FIND_
	.db	0
FIND:
	.dw	compiledWord
	.dw	WORD
	.dw	FIND_
	.dw	CSKIP
	.dw	FINDERR
	.dw	EXIT

	.db	"[']"
	.fill	4
	.dw	$-FIND
	.db	0b01		; IMMEDIATE
FINDI:
	.dw	compiledWord
	.dw	WORD
	.dw	FIND_
	.dw	CSKIP
	.dw	FINDERR
	.dw	LITN
	.dw	EXIT

FINDERR:
	.dw	compiledWord
	.dw	DROP		; Drop str addr, we don't use it
	.dw	LIT
	.db	"word not found", 0
	.dw	PRINT
	.dw	ABORT

; ( -- c )
	.db "KEY"
	.fill 4
	.dw $-FINDI
	.db 0
KEY:
	.dw nativeWord
	call	GETC
	ld	h, 0
	ld	l, a
	push	hl
	jp	next

; This is an indirect word that can be redirected through "CINPTR"
; This is not a real word because it's not meant to be referred to in Forth
; code: it is replaced in readln.fs.
CIN:
	.dw	compiledWord
	.dw	NUMBER
	.dw	CINPTR
	.dw	FETCH
	.dw	EXECUTE
	.dw	EXIT


; ( c -- f )
; 33 CMP 1 + NOT
; The NOT is to normalize the negative/positive numbers to 1 or 0.
; Hadn't we wanted to normalize, we'd have written:
; 32 CMP 1 -
	.db	"WS?"
	.fill	4
	.dw	$-KEY
	.db	0
ISWS:
	.dw	compiledWord
	.dw	NUMBER
	.dw	33
	.dw	CMP
	.dw	ONE
	.dw	PLUS
	.dw	NOT
	.dw	EXIT

	.db	"NOT"
	.fill	4
	.dw	$-ISWS
	.db	0
NOT:
	.dw	nativeWord
	pop	hl
	call	chkPS
	ld	a, l
	or	h
	ld	hl, 0
	jr	nz, .skip	; true, keep at 0
	; false, make 1
	inc	hl
.skip:
	push	hl
	jp	next

; ( -- c )
; C< DUP 32 CMP 1 - SKIP? EXIT DROP TOWORD
	.db	"TOWORD"
	.fill	1
	.dw	$-NOT
	.db	0
TOWORD:
	.dw	compiledWord
	.dw	CIN
	.dw	DUP
	.dw	ISWS
	.dw	CSKIP
	.dw	EXIT
	.dw	DROP
	.dw	TOWORD
	.dw	EXIT

; Read word from C<, copy to WORDBUF, null-terminate, and return, make
; HL point to WORDBUF.
	.db "WORD"
	.fill 3
	.dw $-TOWORD
	.db 0
WORD:
	.dw	compiledWord
	.dw	NUMBER		; ( a )
	.dw	WORDBUF
	.dw	TOWORD		; ( a c )
	; branch mark
	.dw	OVER		; ( a c a )
	.dw	STORE		; ( a )
	.dw	ONE		; ( a 1 )
	.dw	PLUS		; ( a+1 )
	.dw	CIN		; ( a c )
	.dw	DUP		; ( a c c )
	.dw	ISWS		; ( a c f )
	.dw	CSKIP		; ( a c )
	.dw	BBR
	.db	18	; here - mark
	; at this point, we have ( a WS )
	.dw	DROP
	.dw	ZERO
	.dw	SWAP		; ( 0 a )
	.dw	STORE		; ()
	.dw	NUMBER
	.dw	WORDBUF
	.dw	EXIT

.wcpy:
	.dw	nativeWord
	ld	de, WORDBUF
	push	de		; we already have our result
.loop:
	ld	a, (hl)
	cp	' '+1
	jr	c, .loopend
	ld	(de), a
	inc	hl
	inc	de
	jr	.loop
.loopend:
	; null-terminate the string.
	xor	a
	ld	(de), a
	jp	next


	.db	"(parsed"
	.dw	$-WORD
	.db	0
PARSED:
	.dw	nativeWord
	pop	hl
	call	chkPS
	call	parseDecimal
	jr	z, .success
	; error
	ld	de, 0
	push	de	; dummy
	push	de	; flag
	jp	next
.success:
	push	de
	ld	de, 1		; flag
	push	de
	jp	next


	.db	"(parse)"
	.dw	$-PARSED
	.db	0
PARSE:
	.dw	compiledWord
	.dw	PARSED
	.dw	CSKIP
	.dw	.error
	; success, stack is already good, we can exit
	.dw	EXIT

.error:
	.dw	compiledWord
	.dw	LIT
	.db	"unknown word", 0
	.dw	PRINT
	.dw	ABORT


; Indirect parse caller. Reads PARSEPTR and calls
PARSEI:
	.dw	compiledWord
	.dw	PARSEPTR_
	.dw	FETCH
	.dw	EXECUTE
	.dw	EXIT


; Spit name (in (HL)) + prev in (HERE) and adjust (HERE) and (CURRENT)
; HL points to new (HERE)
	.db	"(entry)"
	.dw	$-PARSE
	.db	0
ENTRYHEAD:
	.dw	compiledWord
	.dw	WORD
	.dw	.private
	.dw	EXIT

.private:
	.dw	nativeWord
	pop	hl
	ld	de, (HERE)
	call	strcpy
	ld	hl, (HERE)
	ld	de, (CURRENT)
	ld	a, NAMELEN
	call	addHL
	push	hl		; --> lvl 1
	or	a	; clear carry
	sbc	hl, de
	ex	de, hl
	pop	hl		; <-- lvl 1
	call	DEinHL
	; Set word flags: not IMMED, so it's 0
	xor	a
	ld	(hl), a
	inc	hl
	ld	(CURRENT), hl
	ld	(HERE), hl
	jp	next


	.db "HERE"
	.fill 3
	.dw $-ENTRYHEAD
	.db 0
HERE_:	; Caution: conflicts with actual variable name
	.dw sysvarWord
	.dw HERE

	.db "CURRENT"
	.dw $-HERE_
	.db 0
CURRENT_:
	.dw sysvarWord
	.dw CURRENT

	.db "(parse*"
	.dw $-CURRENT_
	.db 0
PARSEPTR_:
	.dw sysvarWord
	.dw PARSEPTR

	.db	"FLAGS"
	.fill	2
	.dw	$-PARSEPTR_
	.db	0
FLAGS_:
	.dw	sysvarWord
	.dw	FLAGS

	.db	"SYSVNXT"
	.dw	$-FLAGS_
	.db	0
SYSVNXT_:
	.dw	sysvarWord
	.dw	SYSVNXT

; ( n a -- )
	.db "!"
	.fill 6
	.dw $-SYSVNXT_
	.db 0
STORE:
	.dw nativeWord
	pop	iy
	pop	hl
	call	chkPS
	ld	(iy), l
	ld	(iy+1), h
	jp	next

; ( n a -- )
	.db "C!"
	.fill 5
	.dw $-STORE
	.db 0
CSTORE:
	.dw nativeWord
	pop	hl
	pop	de
	call	chkPS
	ld	(hl), e
	jp	next

; ( a -- n )
	.db "@"
	.fill 6
	.dw $-CSTORE
	.db 0
FETCH:
	.dw nativeWord
	pop	hl
	call	chkPS
	call	intoHL
	push	hl
	jp	next

; ( a -- c )
	.db "C@"
	.fill 5
	.dw $-FETCH
	.db 0
CFETCH:
	.dw nativeWord
	pop	hl
	call	chkPS
	ld	l, (hl)
	ld	h, 0
	push	hl
	jp	next

; ( a -- )
	.db "DROP"
	.fill 3
	.dw $-CFETCH
	.db 0
DROP:
	.dw nativeWord
	pop	hl
	jp	next

; ( a b -- b a )
	.db "SWAP"
	.fill 3
	.dw $-DROP
	.db 0
SWAP:
	.dw nativeWord
	pop	hl
	call	chkPS
	ex	(sp), hl
	push	hl
	jp	next

; ( a -- a a )
	.db "DUP"
	.fill 4
	.dw $-SWAP
	.db 0
DUP:
	.dw nativeWord
	pop	hl
	call	chkPS
	push	hl
	push	hl
	jp	next

; ( a b -- a b a )
	.db "OVER"
	.fill 3
	.dw $-DUP
	.db 0
OVER:
	.dw nativeWord
	pop	hl	; B
	pop	de	; A
	call	chkPS
	push	de
	push	hl
	push	de
	jp	next

	.db	">R"
	.fill	5
	.dw	$-OVER
	.db	0
P2R:
	.dw	nativeWord
	pop	hl
	call	chkPS
	call	pushRS
	jp	next

	.db	"R>"
	.fill	5
	.dw	$-P2R
	.db	0
R2P:
	.dw	nativeWord
	call	popRS
	push	hl
	jp	next

	.db	"I"
	.fill	6
	.dw	$-R2P
	.db	0
I:
	.dw	nativeWord
	ld	l, (ix)
	ld	h, (ix+1)
	push	hl
	jp	next

	.db	"I'"
	.fill	5
	.dw	$-I
	.db	0
IPRIME:
	.dw	nativeWord
	ld	l, (ix-2)
	ld	h, (ix-1)
	push	hl
	jp	next

	.db	"J"
	.fill	6
	.dw	$-IPRIME
	.db	0
J:
	.dw	nativeWord
	ld	l, (ix-4)
	ld	h, (ix-3)
	push	hl
	jp	next

; ( a b -- c ) A + B
	.db "+"
	.fill 6
	.dw $-J
	.db 0
PLUS:
	.dw nativeWord
	pop	hl
	pop	de
	call	chkPS
	add	hl, de
	push	hl
	jp	next

; ( a b -- c ) A - B
	.db "-"
	.fill 6
	.dw $-PLUS
	.db 0
MINUS:
	.dw nativeWord
	pop	de		; B
	pop	hl		; A
	call	chkPS
	or	a		; reset carry
	sbc	hl, de
	push	hl
	jp	next

; ( a b -- c ) A * B
	.db "*"
	.fill 6
	.dw $-MINUS
	.db 0
MULT:
	.dw nativeWord
	pop	de
	pop	bc
	call	chkPS
	; DE * BC -> DE (high) and HL (low)
	ld	hl, 0
	ld	a, 0x10
.loop:
	add	hl, hl
	rl	e
	rl	d
	jr	nc, .noinc
	add	hl, bc
	jr	nc, .noinc
	inc	de
.noinc:
	dec a
	jr	nz, .loop
	push	hl
	jp	next


	.db	"/MOD"
	.fill	3
	.dw $-MULT
	.db 0
DIVMOD:
	.dw nativeWord
	pop	de
	pop	hl
	call	chkPS
	call	divide
	push	hl
	push	bc
	jp	next


	.db	"OR"
	.fill	5
	.dw	$-DIVMOD
	.db	0
OR:
	.dw	nativeWord
	pop	hl
	pop	de
	call	chkPS
	ld	a, e
	or	l
	ld	l, a
	ld	a, d
	or	h
	ld	h, a
	push	hl
	jp	next

	.db	"XOR"
	.fill	4
	.dw	$-OR
	.db	0
XOR:
	.dw	nativeWord
	pop	hl
	pop	de
	call	chkPS
	ld	a, e
	xor	l
	ld	l, a
	ld	a, d
	xor	h
	ld	h, a
	push	hl
	jp	next

; It might look peculiar to have specific words for "0" and "1", but although
; it slightly beefs ups the ASM part of the binary, this one-byte-save-per-use
; really adds up when we compare total size.

	.db	"0"
	.fill	6
	.dw	$-XOR
	.db	0
ZERO:
	.dw	nativeWord
	ld	hl, 0
	push	hl
	jp	next

	.db	"1"
	.fill	6
	.dw	$-ZERO
	.db	0
ONE:
	.dw	nativeWord
	ld	hl, 1
	push	hl
	jp	next

; ( a1 a2 -- b )
	.db "SCMP"
	.fill 3
	.dw $-ONE
	.db 0
SCMP:
	.dw nativeWord
	pop	de
	pop	hl
	call	chkPS
	call	strcmp
	call	flagsToBC
	push	bc
	jp	next

; ( n1 n2 -- f )
	.db "CMP"
	.fill 4
	.dw $-SCMP
	.db 0
CMP:
	.dw nativeWord
	pop	hl
	pop	de
	call	chkPS
	or	a	; clear carry
	sbc	hl, de
	call	flagsToBC
	push	bc
	jp	next

; Skip the compword where HL is currently pointing. If it's a regular word,
; it's easy: we inc by 2. If it's a NUMBER, we inc by 4. If it's a LIT, we skip
; to after null-termination.
	.db	"SKIP?"
	.fill	2
	.dw	$-CMP
	.db	0
CSKIP:
	.dw	nativeWord
	pop	hl
	call	chkPS
	ld	a, h
	or	l
	jp	z, next		; False, do nothing.
	ld	hl, (IP)
	ld	de, NUMBER
	call	.HLPointsDE
	jr	z, .isNum
	ld	de, FBR
	call	.HLPointsDE
	jr	z, .isBranch
	ld	de, BBR
	call	.HLPointsDE
	jr	z, .isBranch
	ld	de, LIT
	call	.HLPointsDE
	jr	nz, .isWord
	; We have a literal
	inc	hl \ inc hl
	call	strskip
	inc	hl		; byte after word termination
	jr	.end
.isNum:
	; skip by 4
	inc	hl
	; continue to isBranch
.isBranch:
	; skip by 3
	inc	hl
	; continue to isWord
.isWord:
	; skip by 2
	inc	hl \ inc hl
.end:
	ld	(IP), hl
	jp	next

; Sets Z if (HL) == E and (HL+1) == D
.HLPointsDE:
	ld	a, (hl)
	cp	e
	ret	nz		; no
	inc	hl
	ld	a, (hl)
	dec	hl
	cp	d		; Z has our answer
	ret

; This word's atom is followed by 1b *relative* offset (to the cell's addr) to
; where to branch to. For example, The branching cell of "IF THEN" would
; contain 3. Add this value to RS.
	.db	"(fbr)"
	.fill	2
	.dw	$-CSKIP
	.db	0
FBR:
	.dw	nativeWord
	push	de
	ld	hl, (IP)
	ld	a, (hl)
	call	addHL
	ld	(IP), hl
	pop	de
	jp	next

	.db	"(bbr)"
	.fill	2
	.dw	$-FBR
	.db	0
BBR:
	.dw	nativeWord
	ld	hl, (IP)
	ld	d, 0
	ld	e, (hl)
	or	a		; clear carry
	sbc	hl, de
	ld	(IP), hl
	jp	next

; To allow dict binaries to "hook themselves up", we always end such binary
; with a dummy, *empty* entry. Therefore, we can have a predictable place for
; getting a prev label.

	.db	"_______"
	.dw	$-BBR
	.db	0
