; This repesents a minimal shell, that is, the smallest shell our configuration
; options allow. For a full-featured shell, see "glue.asm"
.inc "user.h"
.inc "err.h"
.inc "ascii.h"
jp	init

.inc "core.asm"
.inc "lib/util.asm"
.inc "lib/parse.asm"
.inc "lib/args.asm"
.inc "lib/fmt.asm"
.equ	SHELL_RAMSTART	USER_RAMSTART
.equ	SHELL_EXTRA_CMD_COUNT	0
.inc "shell/main.asm"

init:
	call	shellInit
	jp	shellLoop

USER_RAMSTART:

