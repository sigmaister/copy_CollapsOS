; Same thing as instr.asm, but for AVR instructions

; *** Instructions table ***

; List of mnemonic names separated by a null terminator. Their index in the
; list is their ID. Unlike in zasm, not all mnemonics have constant associated
; to it because it's generally not needed. This list is grouped by argument
; categories, and then alphabetically. Categories are ordered so that the 8bit
; opcodes come first, then the 16bit ones. 0xff ends the chain
instrNames:
; Branching instructions. They are all shortcuts to BRBC/BRBS. Their respective
; bits are listed in instrBRBits. These are not in alphabetical order, but
; rather in "bit order". All "bit set" instructions first (10th bit clear), then
; all "bit clear" ones (10th bit set). Inside this order, they're then in "sss"
; order (bit number alias for BRBC/BRBS)
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
; no arg (from here, instrUpMasks2)
.equ	I_BREAK	38
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
.equ	I_ASR	64
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
; Rd(5) + K(8): XXXXKKKK ddddKKKK
.db 0b01110000			; ANDI
.db 0b00110000			; CPI
.db 0b11100000			; LDI
.db 0b01100000			; ORI
.db 0b01000000			; SBCI
.db 0b01100000			; SBR
.db 0b01010000			; SUBI

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

instrBRBits:
; 1st bit is 3rd bit of MSB and the other 3 are the lower bits of LSB
.db 0b0000	; BRCS
.db 0b0001	; BREQ
.db 0b0010	; BRMI
.db 0b0011	; BRVS
.db 0b0100	; BRLT
.db 0b0101	; BRHS
.db 0b0110	; BRTS
.db 0b0111	; BRIE
.db 0b1000	; BRCC
.db 0b1001	; BRNE
.db 0b1010	; BRPL
.db 0b1011	; BRVC
.db 0b1100	; BRGE
.db 0b1101	; BRHC
.db 0b1110	; BRTC
.db 0b1111	; BRID

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
	cp	I_ADC
	jp	c, .BR
	cp	I_ANDI
	jr	c, .spitRd5Rr5
	cp	I_BREAK
	jr	c, .spitRdK8
	cp	I_ASR
	jr	c, .spitNoArg
	; spitRd5
	ld	d, a		; save A for later
	call	.readR5
	ret	nz
	call	.placeRd
	ld	a, d		; restore A
	; continue to .spitNoArg
.spitNoArg:
	call	.getUp2
	jr	.spit

.spitRd5Rr5:
	ld	d, a		; save A for later
	call	.readR5
	ret	nz
	call	.placeRd
	call	readComma
	call	.readR5
	ret	nz
	push	af		; --> lvl 1
	; let's start with the 4 lower bits
	and	0xf
	or	c
	; We now have our LSB in A. Let's spit it now.
	call	ioPutB
	pop	af		; <-- lvl 1
	; and now that last high bit, currently bit 4, which must become bit 1
	and	0b00010000
	rra \ rra \ rra
	or	b
	ld	b, a
	ld	a, d		; restore A
	call	.getUp1
	; now that's our MSB
	jr	.spitMSB

.spitRdK8:
	ld	d, a		; save A for later
	call	.readR4
	ret	nz
	call	.placeRd
	call	readComma
	call	readWord
	call	parseExpr
	ret	nz
	ld	a, c
	ld	a, 0xff
	call	.IX2A
	ret	nz
	push	af		; --> lvl 1
	; let's start with the 4 lower bits
	and	0xf
	or	c
	; We now have our LSB in A. Let's spit it now.
	call	ioPutB
	pop	af		; <-- lvl 1
	; and now those high 4 bits
	and	0xf0
	rra \ rra \ rra \ rra
	ld	b, a
	ld	a, d		; restore A
	call	.getUp1
	; now that's our MSB
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
	ld	c, a
.spitBR2:
	call	readWord
	ret	nz
	call	parseExpr
	ret	nz
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
	jp	c, unsetZ	; Carry? error
	ld	de, 0x7f
	sbc	hl, de
	; We're within bounds! However, our value in L is the number of
	; relative *bytes*. The value we put there is the number of words.
	; Thefore, relevant bits are 7:1
	ld	a, l
	sla	a \ rl b
	sla	a \ rl b
	; k is now shifted by 3, two of those bits being in B. Let's OR A and
	; C and we have our LSB ready to go.
	or	c
	call	ioPutB
	; Good! MSB now. B is already good to go.
	ld	a, b
	jp	ioPutB
.rdBRBC:
	; In addition to reading "sss", we also need to inc B so that our base
	; upcode becomes 0b111101
	inc	b
.rdBRBS:
	call	readWord
	ret	nz
	call	parseExpr
	ld	a, 7
	call	.IX2A
	ret	nz
	ld	c, a
	call	readComma
	ret	nz
	jr	.spitBR2

; local routines
; place number in A in BC at position .......d dddd....
; BC is assumed to be 0
.placeRd:
	sla a \ rla \ rla \ rla	; last RLA might set carry
	rl	b
	ld	c, a
	ret

; Fetch a 8-bit upcode specified by instr index in A and set that upcode in HL
.getUp1:
	sub	I_ADC
	ld	hl, instrUpMasks1
	jp	addHL

; Fetch a 16-bit upcode specified by instr index in A and set that upcode in HL
.getUp2:
	sub	I_BREAK
	sla	a	; A * 2
	ld	hl, instrUpMasks2
	jp	addHL

.readR4:
	call	.readR5
	ret	nz
	; has to be in the 16-31 range
	sub	0x10
	jp	c, unsetZ
	cp	a	; ensure Z
	ret

; read a rXX argument and return register number in A.
; Set Z for success.
.readR5:
	call	readWord
	ld	a, (hl)
	call	upcase
	cp	'R'
	ret	nz		; not a register
	inc	hl
	call	parseDecimal
	ret	nz
	ld	a, 31
	jr	.IX2A


; Put IX's LSB into A and, additionally, ensure that the new value is <=
; than what was previously in A.
; Z for success.
.IX2A:
	push	ix \ pop hl
	cp	l
	jp	c, unsetZ	; A < L
	ld	a, h
	or	a
	ret	nz		; should be zero
	ld	a, l
	; Z set from "or a"
	ret
