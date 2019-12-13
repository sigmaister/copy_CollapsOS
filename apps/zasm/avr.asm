; Same thing as instr.asm, but for AVR instructions

; *** Instructions table ***

; List of mnemonic names separated by a null terminator. Their index in the
; list is their ID. Unlike in zasm, not all mnemonics have constant associated
; to it because it's generally not needed. This list is grouped by argument
; categories, and then alphabetically. Categories are ordered so that the 8bit
; opcodes come first, then the 16bit ones. 0xff ends the chain
instrNames:
; Rd(5) + Rr(5)
.equ	I_ADC	0
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
; no arg
.equ	I_BREAK	13
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
.equ	I_ASR	39
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
	cp	I_BREAK
	jr	c, .spitRd5Rr5
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
	ld	hl, instrUpMasks1
	call	addHL
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

; local routines
; place number in A in BC at position .......d dddd....
; BC is assumed to be 0
.placeRd:
	sla a \ rla \ rla \ rla	; last RLA might set carry
	rl	b
	ld	c, a
	ret
; Fetch a 16-bit upcode specified by instr index in A and set that upcode in HL
.getUp2:
	sub	I_BREAK
	sla	a	; A * 2
	ld	hl, instrUpMasks2
	jp	addHL

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
	push	ix \ pop hl
	ld	a, h
	or	a
	ret	nz		; should be zero
	ld	a, l
	cp	32
	jp	nc, unsetZ	; must be < 32
	; we're good!
	cp	a		; ensure Z
	ret
