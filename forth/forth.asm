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

; *** ABI STABILITY ***
;
; This unit needs to have some of its entry points stay at a stable offset.
; These have a comment over them indicating the expected offset. These should
; not move until the Grand Bootstrapping operation has been completed.
;
; When you see random ".fill" here and there, it's to ensure that stability.

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
; *** Const ***
; Base of the Return Stack
.equ	RS_ADDR		0xf000
; Buffer where WORD copies its read word to.
.equ	WORD_BUFSIZE		0x20
; Allocated space for sysvars (see comment above SYSVCNT)
.equ	SYSV_BUFSIZE		0x10

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
; We're at 0 here
	jp	forthMain
.fill 0x08-$
JUMPTBL:
	jp	sysvarWord
	jp	cellWord
	jp	compiledWord
	jp	pushRS
	jp	popRS
	jp	nativeWord
	jp	next
	jp	chkPS
; 24
NUMBER:
	.dw	numberWord
LIT:
	.dw	litWord
	.dw	INITIAL_SP
	.dw	WORDBUF
	jp	flagsToBC
	jp	strcmp

; *** Code ***
forthMain:
	; STACK OVERFLOW PROTECTION:
	; To avoid having to check for stack underflow after each pop operation
	; (which can end up being prohibitive in terms of costs), we give
	; ourselves a nice 6 bytes buffer. 6 bytes because we seldom have words
	; requiring more than 3 items from the stack. Then, at each "exit" call
	; we check for stack underflow.
	ld	sp, 0xfffa
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
	ld	hl, .parseName
	call	find
	ld	(PARSEPTR), de
	; Set up CINPTR
	; do we have a (c<) impl?
	ld	hl, .cinName
	call	find
	jr	z, .skip
	; no? then use KEY
	ld	hl, .keyName
	call	find
.skip:
	ld	(CINPTR), de
	; Set up SYSVNXT
	ld	hl, SYSVBUF
	ld	(SYSVNXT), hl
	ld	hl, .bootName
	call	find
	push	de
	jp	EXECUTE+2

.parseName:
	.db	"(parse)", 0
.cinName:
	.db	"(c<)", 0
.keyName:
	.db	"KEY", 0
.bootName:
	.db	"BOOT", 0

INTERPRET:
	.dw	compiledWord
	.dw	LIT
	.db	"INTERPRET", 0
	.dw	FIND_
	.dw	DROP
	.dw	EXECUTE

.fill 50

; STABLE ABI
; Offset: 00cd
.out $
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
; B indicates the length of the copied string, including null-termination.
strcpy:
	ld	b, 0
.loop:
	ld	a, (hl)
	ld	(de), a
	inc	hl
	inc	de
	inc	b
	or	a
	jr	nz, .loop
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
	cp	'-'
	jr	z, .negative
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

.negative:
	inc	hl
	call	parseDecimal
	ret	nz
	push	hl	; --> lvl 1
	or	a	; clear carry
	ld	hl, 0
	sbc	hl, de
	ex	de, hl
	pop	hl	; <-- lvl 1
	xor	a	; set Z
	ret

; *** Support routines ***
; Find the entry corresponding to word where (HL) points to and sets DE to
; point to that entry.
; Z if found, NZ if not.
find:
	push	bc
	push	hl
	; First, figure out string len
	ld	bc, 0
	xor	a
	cpir
	; C has our length, negative, -1
	ld	a, c
	neg
	dec	a
	; special case. zero len? we never find anything.
	jr	z, .fail
	ld	c, a		; C holds our length
	; Let's do something weird: We'll hold HL by the *tail*. Because of our
	; dict structure and because we know our lengths, it's easier to
	; compare starting from the end. Currently, after CPIR, HL points to
	; char after null. Let's adjust
	; Because the compare loop pre-decrements, instead of DECing HL twice,
	; we DEC it once.
	dec	hl
	ld	de, (CURRENT)
.inner:
	; DE is a wordref. First step, do our len correspond?
	push	hl		; --> lvl 1
	push	de		; --> lvl 2
	dec	de
	ld	a, (de)
	and	0x7f		; remove IMMEDIATE flag
	cp	c
	jr	nz, .loopend
	; match, let's compare the string then
	dec	de \ dec de	; skip prev field. One less because we
				; pre-decrement
	ld	b, c		; loop C times
.loop:
	; pre-decrement for easier Z matching
	dec	de
	dec	hl
	ld	a, (de)
	cp	(hl)
	jr	nz, .loopend
	djnz	.loop
.loopend:
	; At this point, Z is set if we have a match. In all cases, we want
	; to pop HL and DE
	pop	de		; <-- lvl 2
	pop	hl		; <-- lvl 1
	jr	z, .end		; match? we're done!
	; no match, go to prev and continue
	push	hl			; --> lvl 1
	dec	de \ dec de \ dec de	; prev field
	push	de			; --> lvl 2
	ex 	de, hl
	call 	intoHL
	ex 	de, hl			; DE contains prev offset
	pop	hl			; <-- lvl 2
	; HL is prev field's addr
	; Is offset zero?
	ld	a, d
	or	e
	jr	z, .noprev		; no prev entry
	; get absolute addr from offset
	; carry cleared from "or e"
	sbc	hl, de
	ex	de, hl			; result in DE
.noprev:
	pop	hl			; <-- lvl 1
	jr	nz, .inner		; try to match again
	; Z set? end of dict unset Z
.fail:
	xor	a
	inc	a
.end:
	pop	hl
	pop	bc
	ret

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
; - Xb name. Arbitrary long number of character (but can't be bigger than
;   input buffer, of course). not null-terminated
; - 2b prev offset
; - 1b size + IMMEDIATE flag
; - 2b code pointer
; - Parameter field (PF)
;
; The prev offset is the number of bytes between the prev field and the
; previous word's code pointer.
;
; The size + flag indicate the size of the name field, with the 7th bit
; being the IMMEDIATE flag.
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

; Pop previous IP from Return stack and execute it.
; ( R:I -- )
	.db	"EXIT"
	.dw	0
	.db	4
EXIT:
	.dw nativeWord
	call	popRSIP
	jp	next

; ( R:I -- )
	.db "QUIT"
	.dw $-EXIT
	.db 4
QUIT:
	.dw compiledWord
	.dw	NUMBER
	.dw	0
	.dw	FLAGS_
	.dw	STORE
	.dw	.private
	.dw	INTERPRET

.private:
	.dw	nativeWord
	ld	ix, RS_ADDR
	jp	next

abortUnderflow:
	ld	hl, .name
	call	find
	push	de
	jp	EXECUTE+2
.name:
	.db "(uflw)", 0

	.db	"(br)"
	.dw	$-QUIT
	.db	4
BR:
	.dw	nativeWord
	ld	hl, (IP)
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	dec	hl
	add	hl, de
	ld	(IP), hl
	jp	next

.fill 72

	.db	"(?br)"
	.dw	$-BR
	.db	5
CBR:
	.dw	nativeWord
	pop	hl
	call	chkPS
	ld	a, h
	or	l
	jp	z, BR+2		; False, branch
	; True, skip next 2 bytes and don't branch
	ld	hl, (IP)
	inc	hl
	inc	hl
	ld	(IP), hl
	jp	next

.fill 15

	.db	","
	.dw	$-CBR
	.db	1
WR:
	.dw	nativeWord
	pop	de
	call	chkPS
	ld	hl, (HERE)
	call	DEinHL
	ld	(HERE), hl
	jp	next

.fill 100

; ( addr -- )
	.db "EXECUTE"
	.dw $-WR
	.db 7
; STABLE ABI
; Offset: 0388
.out $
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


.fill 77

	.db "DOES>"
	.dw $-EXECUTE
	.db 5
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


.fill 82

	.db	"SCPY"
	.dw	$-DOES
	.db	4
SCPY:
	.dw	nativeWord
	pop	hl
	ld	de, (HERE)
	call	strcpy
	ld	(HERE), de
	jp	next


	.db	"(find)"
	.dw	$-SCPY
	.db	6
; STABLE ABI
; Offset: 047c
.out $
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

; This is an indirect word that can be redirected through "CINPTR"
; code: it is replaced in readln.fs.
	.db "C<"
	.dw $-FIND_
	.db 2
CIN:
	.dw	compiledWord
	.dw	NUMBER
	.dw	CINPTR
	.dw	FETCH
	.dw	EXECUTE
	.dw	EXIT


.fill 24

	.db	"NOT"
	.dw	$-CIN
	.db	3
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


.fill 100

	.db	"(parsed)"
	.dw	$-NOT
	.db	8
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


.fill 96

	.db	"JTBL"
	.dw	$-PARSED
	.db	4
JTBL:
	.dw	sysvarWord
	.dw	JUMPTBL

; STABLE ABI (every sysvars)
; Offset: 05ca
.out $
	.db "HERE"
	.dw $-JTBL
	.db 4
HERE_:	; Caution: conflicts with actual variable name
	.dw sysvarWord
	.dw HERE

	.db "CURRENT"
	.dw $-HERE_
	.db 7
CURRENT_:
	.dw sysvarWord
	.dw CURRENT

	.db "(parse*)"
	.dw $-CURRENT_
	.db 8
PARSEPTR_:
	.dw sysvarWord
	.dw PARSEPTR

	.db	"FLAGS"
	.dw	$-PARSEPTR_
	.db	5
FLAGS_:
	.dw	sysvarWord
	.dw	FLAGS

	.db	"SYSVNXT"
	.dw	$-FLAGS_
	.db	7
SYSVNXT_:
	.dw	sysvarWord
	.dw	SYSVNXT

; ( n a -- )
	.db "!"
	.dw $-SYSVNXT_
	.db 1
; STABLE ABI
; Offset: 0610
.out $
STORE:
	.dw nativeWord
	pop	iy
	pop	hl
	call	chkPS
	ld	(iy), l
	ld	(iy+1), h
	jp	next

; ( a -- n )
	.db "@"
	.dw $-STORE
	.db 1
FETCH:
	.dw nativeWord
	pop	hl
	call	chkPS
	call	intoHL
	push	hl
	jp	next

; ( a -- )
	.db "DROP"
	.dw $-FETCH
	.db 4
; STABLE ABI
DROP:
	.dw nativeWord
	pop	hl
	jp	next

.fill 167

	.db	"_bend"
	.dw	$-DROP
	.db	5
; Offset: 06ee
.out $
