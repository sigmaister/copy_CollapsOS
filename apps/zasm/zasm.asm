#include "user.inc"
.org	USER_CODE
call	parseLine
ld	b, 0
ld	c, a	; written bytes
ret

; Sets Z is A is ' ', CR, LF, or null.
isSep:
	cp	' '
	ret	z
	cp	0
	ret	z
	cp	0x0d
	ret	z
	cp	0x0a
	ret

; read word in (HL) and put it in curWord, null terminated. A is the read
; length.
readWord:
	push	bc
	push	de
	push	hl
	ld	de, curWord
	ld	b, 4
.loop:
	ld	a, (hl)
	call	isSep
	jr	z, .success
	call	JUMP_UPCASE
	ld	(de), a
	inc	hl
	inc	de
	djnz	.loop
.success:
	xor	a
	ld	(de), a
	ld	a, 4
	sub	a, b
	jr	.end
.error:
	xor	a
	ld	(de), a
.end:
	pop	hl
	pop	de
	pop	bc
	ret

; Compare primary row at (DE) with string at curWord. Sets Z flag if there's a
; match, reset if not.
matchPrimaryRow:
	push	hl
	ld	hl, curWord
	ld	a, 4
	call	JUMP_STRNCMP
	pop	hl
	ret

; Parse line at (HL) and write resulting opcode(s) in (DE). Returns the number
; of bytes written in A.
parseLine:
	call	readWord
	push	de
	ld	de, instTBlPrimary
.loop:
	ld	a, (de)
	cp	0
	jr	z, .nomatch	; we reached last entry
	call	matchPrimaryRow
	jr	z, .match
	ld	a, 7
	call	JUMP_ADDDE
	jr	.loop

.nomatch:
	xor	a
	pop	de
	ret
.match:
	ld	a, 6	; upcode is on 7th byte
	call	JUMP_ADDDE
	ld	a, (de)
	pop	de
	ld	(de), a
	ld	a, 1
	ret

; This is a list of primary instructions (single upcode) that lead to a
; constant (no group code to insert).
; That doesn't mean that they don't take any argument though. For example,
; "DEC IX" leads to a special upcode. These kind of constants are indicated
; as a single byte to save space. Meaning:
;
; All single char registers (A/B/C etc) -> themselves
; HL -> h
; (HL) -> l
; DE -> d
; (DE) -> e
; BC -> b
; (BC) -> c
; IX -> X
; (IX) -> x
; IY -> Y
; (IY) -> y
; AF -> a
; AF' -> f
; SP -> s
; (SP) -> p
; None -> 0
;
; This is a sorted list of "primary" (single byte) instructions along with
; metadata
; 4 bytes for the name (fill with zero)
; 1 byte for arg constant
; 1 byte for 2nd arg constant
; 1 byte for upcode
instTBlPrimary:
	.db "ADD", 0, 'A', 'h', 0x86		; ADD A, HL
	.db "CCF", 0, 0,   0,   0x3f		; CCF
	.db "CPL", 0, 0,   0,   0x2f		; CPL
	.db "DAA", 0, 0,   0,   0x27		; DAA
	.db "DI",0,0, 0,   0,   0xf3		; DI
	.db "EI",0,0, 0,   0,   0xfb		; EI
	.db "EX",0,0, 'p', 'h', 0xe3		; EX (SP), HL
	.db "EX",0,0, 'a', 'f', 0x08		; EX AF, AF'
	.db "EX",0,0, 'd', 'h', 0xeb		; EX DE, HL
	.db "EXX", 0, 0,   0,   0xd9		; EXX
	.db "HALT",   0,   0,   0x76		; HALT
	.db "INC", 0, 'l', 0,   0x34		; INC (HL)
	.db "JP",0,0, 'l', 0,   0xe9		; JP (HL)
	.db "LD",0,0, 'c', 'A', 0x02		; LD (BC), A
	.db "LD",0,0, 'e', 'A', 0x12		; LD (DE), A
	.db "LD",0,0, 'A', 'c', 0x0a		; LD A, (BC)
	.db "LD",0,0, 'A', 'e', 0x0a		; LD A, (DE)
	.db "LD",0,0, 's', 'h', 0x0a		; LD SP, HL
	.db "NOP", 0, 0,   0,   0x00		; NOP
	.db "RET", 0, 0,   0,   0xc9		; RET
	.db "RLA", 0, 0,   0,   0x17		; RLA
	.db "RLCA",   0,   0,   0x07		; RLCA
	.db "RRA", 0, 0,   0,   0x1f		; RRA
	.db "RRCA",   0,   0,   0x0f		; RRCA
	.db "SCF", 0, 0,   0,   0x37		; SCF
	.db 0

; *** Variables ***
; enough space for 4 chars and a null
curWord:
	.db	0, 0, 0, 0, 0
