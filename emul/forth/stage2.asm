	jp	init

.inc "stagec.asm"
.inc "forth.asm"

.out $		; should be the same as in stage{0,1}
.bin "z80c.bin"
.bin "core.bin"
CODE_END:

