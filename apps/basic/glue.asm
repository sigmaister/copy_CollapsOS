; *** Requirements ***
; printstr
; printcrlf
; stdioReadLine
; strncmp
;
.inc "user.h"
.inc "err.h"

	jp	basStart

; RAM space used in different routines for short term processing.
.equ	SCRATCHPAD_SIZE	0x20
.equ	SCRATCHPAD	USER_RAMSTART

.inc "core.asm"
.inc "lib/util.asm"
.inc "lib/ari.asm"
.inc "lib/parse.asm"
.inc "lib/fmt.asm"
.equ	EXPR_PARSE	parseLiteralOrVar
.inc "lib/expr.asm"
.inc "basic/util.asm"
.inc "basic/parse.asm"
.inc "basic/tok.asm"
.equ	VAR_RAMSTART	SCRATCHPAD+SCRATCHPAD_SIZE
.inc "basic/var.asm"
.equ	BUF_RAMSTART	VAR_RAMEND
.inc "basic/buf.asm"
.equ	BAS_RAMSTART	BUF_RAMEND
.inc "basic/main.asm"
USER_RAMSTART:
