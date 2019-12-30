; avra
;
; This glue code assembles as assembler for AVR microcontrollers. It looks a
; lot like zasm, but it spits AVR binary. Comments have been stripped, refer
; to glue.asm for details.

.inc "user.h"

; *** Overridable consts ***
.equ	ZASM_REG_MAXCNT		0xff
.equ	ZASM_LREG_MAXCNT	0x20
.equ	ZASM_REG_BUFSZ		0x700
.equ	ZASM_LREG_BUFSZ		0x100

; ******

.inc "err.h"
.inc "ascii.h"
.inc "blkdev.h"
.inc "fs.h"
jp	zasmMain

.inc "core.asm"
.inc "zasm/const.asm"
.inc "lib/util.asm"
.inc "lib/ari.asm"
.inc "lib/parse.asm"
.inc "zasm/util.asm"
.equ	IO_RAMSTART	USER_RAMSTART
.inc "zasm/io.asm"
.equ	TOK_RAMSTART	IO_RAMEND
.inc "zasm/tok.asm"
.inc "zasm/avr.asm"
.equ	DIREC_RAMSTART	TOK_RAMEND
.inc "zasm/directive.asm"
.inc "zasm/parse.asm"
.equ	EXPR_PARSE	parseNumberOrSymbol
.inc "lib/expr.asm"
.equ	SYM_RAMSTART	DIREC_RAMEND
.inc "zasm/symbol.asm"
.equ	ZASM_RAMSTART	SYM_RAMEND
.inc "zasm/main.asm"
USER_RAMSTART:

