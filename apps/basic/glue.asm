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
.equ	EXPR_PARSE	parseLiteralOrVar
.inc "lib/expr.asm"
.inc "basic/tok.asm"
.equ	VAR_RAMSTART	USER_RAMSTART
.inc "basic/var.asm"
.equ	BUF_RAMSTART	VAR_RAMEND
.inc "basic/buf.asm"
.equ	BAS_RAMSTART	BUF_RAMEND
.inc "basic/main.asm"
USER_RAMSTART:
