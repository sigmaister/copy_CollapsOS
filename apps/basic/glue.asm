; *** Requirements ***
; addHL
; printstr
; printcrlf
; stdioReadLine
; strncmp
;
.inc "user.h"

.inc "err.h"
.org	USER_CODE

	jp	basStart

.inc "lib/parse.asm"
.equ	BAS_RAMSTART	USER_RAMSTART
.inc "basic/main.asm"
