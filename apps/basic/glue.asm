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
.inc "basic/tok.asm"
.equ	BAS_RAMSTART	USER_RAMSTART
.inc "basic/main.asm"
USER_RAMSTART:
