; Same thing as instr.asm, but for AVR instructions

; *** Instructions table ***

; List of mnemonic names separated by a null terminator. Their index in the
; list is their ID. Unlike in zasm, not all mnemonics have constant associated
; to it because it's generally not needed. This list is grouped by argument
; categories, and then alphabetically. Categories are ordered so that the 8bit
; opcodes come first, then the 16bit ones. 0xff ends the chain
instrNames:
; Branching instructions. They are all shortcuts to BRBC/BRBS. These are not in
; alphabetical order, but rather in "bit order". All "bit set" instructions
; first (10th bit clear), then all "bit clear" ones (10th bit set). Inside this
; order, they're then in "sss" order (bit number alias for BRBC/BRBS).
.db "BRCS", 0
.db "BREQ", 0
.db "BRMI", 0
.db "BRVS", 0
.db "BRLT", 0
.db "BRHS", 0
.db "BRTS", 0
.db "BRIE", 0
.db "BRCC", 0
.db "BRNE", 0
.db "BRPL", 0
.db "BRVC", 0
.db "BRGE", 0
.db "BRHC", 0
.db "BRTC", 0
.db "BRID", 0
.equ	I_BRBS	16
.db "BRBS", 0
.db "BRBC", 0
; Rd(5) + Rr(5) (from here, instrUpMasks1)
.equ	I_ADC	18
.db "ADC", 0
.db "ADD", 0
.db "AND", 0
.db "CLR", 0
.db "CP", 0
.db "CPC", 0
.db "CPSE", 0
.db "EOR", 0
.db "MOV", 0
.db "MUL", 0
.db "OR", 0
.db "SBC", 0
.db "SUB", 0
.equ	I_ANDI	31
.db "ANDI", 0
.db "CPI", 0
.db "LDI", 0
.db "ORI", 0
.db "SBCI", 0
.db "SBR", 0
.db "SUBI", 0
.equ	I_BLD	38
.db "BLD", 0
.db "BST", 0
.db "SBRC", 0
.db "SBRS", 0
.equ	I_RCALL	42
.db "RCALL", 0
.db "RJMP", 0
.equ	I_IN	44
.db "IN", 0
.equ	I_OUT	45
.db "OUT", 0
; no arg (from here, instrUpMasks2)
.equ	I_BREAK	46
.db "BREAK", 0
.db "CLC", 0
.db "CLH", 0
.db "CLI", 0
.db "CLN", 0
.db "CLS", 0
.db "CLT", 0
.db "CLV", 0
.db "CLZ", 0
.db "EICALL", 0
.db "EIJMP", 0
.db "ICALL", 0
.db "IJMP", 0
.db "NOP", 0
.db "RET", 0
.db "RETI", 0
.db "SEC", 0
.db "SEH", 0
.db "SEI", 0
.db "SEN", 0
.db "SES", 0
.db "SET", 0
.db "SEV", 0
.db "SEZ", 0
.db "SLEEP", 0
.db "WDR", 0
; Rd(5)
.equ	I_ASR	72
.db "ASR", 0
.db "COM", 0
.db "DEC", 0
.db "INC", 0
.db "LAC", 0
.db "LAS", 0
.db "LAT", 0
.db "LSR", 0
.db "NEG", 0
.db "POP", 0
.db "PUSH", 0
.db "ROR", 0
.db "SWAP", 0
.db "XCH", 0
.db 0xff


; 8-bit constant masks associated with each instruction. In the same order as
; in instrNames
instrUpMasks1:
; Rd(5) + Rd(5): XXXXXXrd ddddrrrr
.db 0b00011100			; ADC
.db 0b00001100			; ADD
.db 0b00100000			; AND
.db 0b00100100			; CLR
.db 0b00010100			; CP
.db 0b00000100			; CPC
.db 0b00010000			; CPSE
.db 0b00100100			; EOR
.db 0b00101100			; MOV
.db 0b10011100			; MUL
.db 0b00101000			; OR
.db 0b00001000			; SBC
.db 0b00011000			; SUB
; Rd(4) + K(8): XXXXKKKK ddddKKKK
.db 0b01110000			; ANDI
.db 0b00110000			; CPI
.db 0b11100000			; LDI
.db 0b01100000			; ORI
.db 0b01000000			; SBCI
.db 0b01100000			; SBR
.db 0b01010000			; SUBI
; Rd(5) + bit: XXXXXXXd ddddXbbb: lonely bit in LSB is 0 in all cases, so we
; ignore it.
.db 0b11111000			; BLD
.db 0b11111010			; BST
.db 0b11111100			; SBRC
.db 0b11111110			; SBRS
; k(12): XXXXkkkk kkkkkkkk
.db 0b11010000			; RCALL
.db 0b11000000			; RJMP
; IN and OUT
.db 0b10110000			; IN
.db 0b10111000			; OUT

; 16-bit constant masks associated with each instruction. In the same order as
; in instrNames
instrUpMasks2:
; no arg
.db 0b10010101, 0b10011000	; BREAK
.db 0b10010100, 0b10001000	; CLC
.db 0b10010100, 0b11011000	; CLH
.db 0b10010100, 0b11111000	; CLI
.db 0b10010100, 0b10101000	; CLN
.db 0b10010100, 0b11001000	; CLS
.db 0b10010100, 0b11101000	; CLT
.db 0b10010100, 0b10111000	; CLV
.db 0b10010100, 0b10011000	; CLZ
.db 0b10010101, 0b00011001	; EICALL
.db 0b10010100, 0b00011001	; EIJMP
.db 0b10010101, 0b00001001	; ICALL
.db 0b10010100, 0b00001001	; IJMP
.db 0b00000000, 0b00000000	; NOP
.db 0b10010101, 0b00001000	; RET
.db 0b10010101, 0b00011000	; RETI
.db 0b10010100, 0b00001000	; SEC
.db 0b10010100, 0b01011000	; SEH
.db 0b10010100, 0b01111000	; SEI
.db 0b10010100, 0b00101000	; SEN
.db 0b10010100, 0b01001000	; SES
.db 0b10010100, 0b01101000	; SET
.db 0b10010100, 0b00111000	; SEV
.db 0b10010100, 0b00011000	; SEZ
.db 0b10010101, 0b10001000	; SLEEP
.db 0b10010101, 0b10101000	; WDR
; Rd(5): XXXXXXXd ddddXXXX
.db 0b10010100, 0b00000101	; ASR
.db 0b10010100, 0b00000000	; COM
.db 0b10010100, 0b00001010	; DEC
.db 0b10010100, 0b00000011	; INC
.db 0b10010010, 0b00000110	; LAC
.db 0b10010010, 0b00000101	; LAS
.db 0b10010010, 0b00000111	; LAT
.db 0b10010100, 0b00000110	; LSR
.db 0b10010100, 0b00000001	; NEG
.db 0b10010000, 0b00001111	; POP
.db 0b10010010, 0b00001111	; PUSH
.db 0b10010100, 0b00000111	; ROR
.db 0b10010100, 0b00000010	; SWAP
.db 0b10010010, 0b00000100	; XCH

; Same signature as getInstID in instr.asm
; Reads string in (HL) and returns the corresponding ID (I_*) in A. Sets Z if
; there's a match.
getInstID:
	push	bc
	push	hl
	push	de
	ex	de, hl		; DE makes a better needle
	; haystack. -1 because we inc HL at the beginning of the loop
	ld	hl, instrNames-1
	ld	b, 0xff		; index counter
.loop:
	inc	b
	inc	hl
	ld	a, (hl)
	inc	a		; check if 0xff
	jr	z, .notFound
	call	strcmpIN
	jr	nz, .loop
	; found!
	ld	a, b		; index
	cp	a		; ensure Z
.end:
	pop	de
	pop	hl
	pop	bc
	ret
.notFound:
	dec	a		; unset Z
	jr	.end

; Same signature as parseInstruction in instr.asm
; Parse instruction specified in A (I_* const) with args in I/O and write
; resulting opcode(s) in I/O.
; Sets Z on success. On error, A contains an error code (ERR_*)
parseInstruction:
	; BC, during .spit, is ORred to the spitted opcode.
	ld	bc, 0
	; Save Instr ID in D, which is less volatile than A. In almost all
	; cases, we fetch the opcode constant at the end of the processing.
	ld	d, a
	cp	I_ADC
	jp	c, .BR
	cp	I_ANDI
	jr	c, .spitRd5Rr5
	cp	I_BLD
	jr	c, .spitRdK8
	cp	I_RCALL
	jr	c, .spitRdBit
	cp	I_IN
	jr	c, .spitK12
	jp	z, .spitIN
	cp	I_OUT
	jp	z, .spitOUT
	cp	I_ASR
	jr	c, .spitNoArg
	; spitRd5
	ld	ix, argSpecs	; 'R', 0
	call	_parseArgs
	ld	a, h
	call	.placeRd
	; continue to .spitNoArg
.spitNoArg:
	call	.getUp2
	jp	.spit

.spitRd5Rr5:
	ld	ix, argSpecs+2	; 'R', 'R'
	call	_parseArgs
	ret	nz
	ld	a, h
	call	.placeRd
	ld	a, l
	; let's start with the 4 lower bits
	and	0xf
	or	c
	; We now have our LSB in A. Let's spit it now.
	call	ioPutB
	ld	a, l
	; and now that last high bit, currently bit 4, which must become bit 1
	and	0b00010000
	rra \ rra \ rra
	or	b
	ld	b, a
	call	.getUp1
	; now that's our MSB
	jp	.spitMSB

.spitRdK8:
	ld	ix, argSpecs+6		; 'r', 8
	call	_parseArgs
	ret	nz
	ld	a, h		; Rd
	call	.placeRd
	ld	a, l		; K
	; let's start with the 4 lower bits
	and	0xf
	or	c
	; We now have our LSB in A. Let's spit it now.
	call	ioPutB
	ld	a, l
	; and now those high 4 bits
	and	0xf0
	rra \ rra \ rra \ rra
	ld	b, a
	call	.getUp1
	jp	.spitMSB

.spitRdBit:
	ld	ix, argSpecs+8		; 'R', 'b'
	call	_parseArgs
	ret	nz
	ld	a, h
	call	.placeRd
	or	l
	; LSB is in A and is ready to go
	call	ioPutB
	call	.getUp1
	jr	.spitMSB

.spitK12:
	; Let's deal with the upcode constant before we destroy DE below
	call	.getUp1
	ld	b, (hl)
	call	readWord
	call	parseExpr
	ret	nz
	push	ix \ pop hl
	; We're doing the same dance as in _readk7. See comments there.
	ld	de, 0xfff
	add	hl, de
	jp	c, unsetZ	; Carry? number is way too high.
	ex	de, hl
	call	zasmGetPC	; --> HL
	inc	hl \ inc hl
	ex	de, hl
	sbc	hl, de
	jp	c, unsetZ	; Carry? error
	ld	de, 0xfff
	sbc	hl, de
	; We're within bounds! Now, divide by 2
	ld	a, l
	rr	h \ rra
	; LSB in A, spit
	call	ioPutB
	ld	a, h
	and	0xf
	or	b
	jp	ioPutB

.spitOUT:
	ld	ix, argSpecs+12		; 'A', 'R'
	call	_parseArgs
	ret	nz
	ld	a, h
	ld	h, l
	ld	l, a
	jr	.spitINOUT
.spitIN:
	ld	ix, argSpecs+14		; 'R', 'A'
	call	_parseArgs
	ret	nz
.spitINOUT:
	; Rd in H, A in L
	ld	a, h
	call	.placeRd
	ld	a, l
	and	0xf
	or	c
	; LSB ready
	call	ioPutB
	; The two high bits of A go in bits 3:1 of MSB
	ld	a, l
	rra \ rra \ rra
	and	0b110
	or	b
	ld	b, a
	; MSB is almost ready
	call	.getUp1
	jr	.spitMSB
.spit:
	; LSB is spit *before* MSB
	inc	hl
	ld	a, (hl)
	or	c
	call	ioPutB
	dec	hl
.spitMSB:
	ld	a, (hl)
	or	b
	call	ioPutB
	xor	a		; ensure Z, set success
	ret

; Spit a branching mnemonic.
.BR:
	; While we have our index in A, let's settle B straight: Our base
	; upcode is 0b11110000 for "bit set" types and 0b11110100 for "bit
	; clear" types. However, we'll have 2 left shift operation done on B
	; later on, so we need those bits shifted right.
	ld	b, 0b111100
	cp	I_BRBS
	jr	z, .rdBRBS
	jr	nc, .rdBRBC
	; We have an alias. Our "sss" value is index & 0b111
	; Before we get rid of that 3rd bit, let's see, is it set? if yes, we'll
	; want to increase B
	bit	3, a
	jr	z, .skip1	; 3rd bit unset
	inc	b
.skip1:
	and	0b111
	ld	c, a		; can't store in H now, (HL) is used
	ld	ix, argSpecs+4	; 7, 0
	call	_parseArgs
	ret	nz
	; ok, now we can
	ld	l, h		; k in L
	ld	h, c		; bit in H
.spitBR2:
	; bit in H, k in L.
	; Our value in L is the number of relative *bytes*. The value we put
	; there is the number of words. Therefore, relevant bits are 7:1
	ld	a, l
	sla	a \ rl b
	sla	a \ rl b
	and	0b11111000
	; k is now shifted by 3, two of those bits being in B. Let's OR A and
	; H and we have our LSB ready to go.
	or	h
	call	ioPutB
	; Good! MSB now. B is already good to go.
	ld	a, b
	jp	ioPutB
.rdBRBC:
	; In addition to reading "sss", we also need to inc B so that our base
	; upcode becomes 0b111101
	inc	b
.rdBRBS:
	ld	ix, argSpecs+10		; bit + k(7)
	call	_parseArgs
	ret	nz
	; bit in H, k in L.
	jr	.spitBR2

; local routines
; place number in A in BC at position .......d dddd....
; BC is assumed to be 0
.placeRd:
	sla a \ rla \ rla \ rla	; last RLA might set carry
	rl	b
	ld	c, a
	ret

; Fetch a 8-bit upcode specified by instr index in D and set that upcode in HL
.getUp1:
	ld	a, d
	sub	I_ADC
	ld	hl, instrUpMasks1
	jp	addHL

; Fetch a 16-bit upcode specified by instr index in D and set that upcode in HL
.getUp2:
	ld	a, d
	sub	I_BREAK
	sla	a	; A * 2
	ld	hl, instrUpMasks2
	jp	addHL

; Argspecs: two bytes describing the arguments that are accepted. Possible
; values:
;
; 0 - None
; 7 - a k(7) address, relative to PC, *in bytes* (divide by 2 before writing)
; 8 - a K(8) value
; 'a' - A 5-bit I/O port value
; 'A' - A 6-bit I/O port value
; 'b' - a 0-7 bit value
; 'R' - an r5 value: r0-r31
; 'r' - an r4 value: r16-r31
;
; All arguments accept expressions, even 'r' ones: in 'r' args, we start by
; looking if the arg starts with 'r' or 'R'. If yes, it's a simple 'rXX' value,
; if not, we try parsing it as an expression and validate that it falls in the
; correct 0-31 or 16-31 range
argSpecs:
	.db	'R', 0		; Rd(5)
	.db	'R', 'R'	; Rd(5) + Rr(5)
	.db	7, 0		; k(7)
	.db	'r', 8		; Rd(4) + K(8)
	.db	'R', 'b'	; Rd(5) + bit
	.db	'b', 7		; bit + k(7)
	.db	'A', 'R'	; A(6) + Rr(5)
	.db	'R', 'A'	; Rd(5) + A(6)

; Parse arguments in (HL) according to specs in IX
; Puts the results in HL (which is not needed anymore after the parsing).
; First arg in H, second in L.
; This routine is not used in all cases, some ops don't fit this pattern well
; and thus parse their args themselves.
; Z for success.
_parseArgs:
	; For the duration of the routine, our final value will be in DE, and
	; then placed in HL at the end.
	push	de
	call	readWord
	jr	nz, .end
	ld	a, (ix)
	call	.parse
	jr	nz, .end
	ld	d, a
	ld	a, (ix+1)
	or	a
	jr	z, .end		; no arg
	call	readComma
	jr	nz, .end
	call	readWord
	jr	nz, .end
	ld	a, (ix+1)
	call	.parse
	jr	nz, .end
	; we're done with (HL) now
	ld	l, a
	cp	a		; ensure Z
.end:
	ld	h, d
	pop	de
	ret

; Parse a single arg specified in A and returns its value in A
; Z for success
.parse:
	cp	'R'
	jr	z, _readR5
	cp	'r'
	jr	z, _readR4
	cp	'b'
	jr	z, _readBit
	cp	'A'
	jr	z, _readA6
	cp	7
	jr	z, _readk7
	cp	8
	jr	z, _readK8
	ret			; something's wrong

; Read expr and return success only if result in under number given in A
; Z for success
_readExpr:
	push	ix
	push	bc
	ld	b, a
	call	parseExpr
	jr	nz, .end
	ld	a, b
	call	_IX2A
	jr	nz, .end
	or	c
	ld	c, a
	cp	a		; ensure Z
.end:
	pop	bc
	pop	ix
	ret

_readBit:
	ld	a, 7
	jr	_readExpr

_readA6:
	ld	a, 0x3f

_readK8:
	ld	a, 0xff
	jr	_readExpr

_readk7:
	push	hl
	push	de
	push	ix
	call	parseExpr
	jr	nz, .end
	; IX contains an absolute value. Turn this into a -64/+63 relative
	; value by subtracting PC from it. However, before we do that, let's
	; add 0x7f to it, which we'll remove later. This will simplify bounds
	; checks. (we use 7f instead of 3f because we deal in bytes here, not
	; in words)
	push	ix \ pop hl
	ld	de, 0x7f
	add	hl, de		; Carry cleared
	ex	de, hl
	call	zasmGetPC	; --> HL
	; The relative value is actually not relative to current PC, but to
	; PC after the execution of this branching op. Increase HL by 2.
	inc	hl \ inc hl
	ex	de, hl
	sbc	hl, de
	jp	c, .err	; Carry? error
	ld	de, 0x7f
	sbc	hl, de
	; We're within bounds! However, our value in L is the number of
	; relative *bytes*.
	ld	a, l
	cp	a		; ensure Z
.end:
	pop	ix
	pop	de
	pop	hl
	ret
.err:
	call	unsetZ
	jr	.end

_readR4:
	call	_readR5
	ret	nz
	; has to be in the 16-31 range
	sub	0x10
	jp	c, unsetZ
	cp	a	; ensure Z
	ret

; read a rXX argument and return register number in A.
; Set Z for success.
_readR5:
	push	ix
	ld	a, (hl)
	call	upcase
	cp	'R'
	jr	nz, .end		; not a register
	inc	hl
	call	parseDecimal
	jr	nz, .end
	ld	a, 31
	call	_IX2A
.end:
	pop	ix
	ret

; Put IX's LSB into A and, additionally, ensure that the new value is <=
; than what was previously in A.
; Z for success.
_IX2A:
	push	ix \ pop hl
	cp	l
	jp	c, unsetZ	; A < L
	ld	a, h
	or	a
	ret	nz		; should be zero
	ld	a, l
	; Z set from "or a"
	ret


