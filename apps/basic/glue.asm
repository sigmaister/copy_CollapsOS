; *** Requirements ***
; printstr
; printcrlf
; stdioReadLine
; strncmp
;
.inc "user.h"
.inc "err.h"

	jp	basStart

.inc "core.asm"
.inc "lib/util.asm"
.inc "lib/ari.asm"
.inc "lib/parse.asm"
.inc "lib/fmt.asm"
.equ	EXPR_PARSE	parseLiteral
.inc "lib/expr.asm"
.inc "basic/tok.asm"
.equ	BUF_RAMSTART	USER_RAMSTART
.inc "basic/buf.asm"
.equ	BAS_RAMSTART	BUF_RAMEND
.inc "basic/main.asm"
USER_RAMSTART:
