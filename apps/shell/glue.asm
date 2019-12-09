; This repesents a full-featured shell, that is, a shell that includes all
; options it has to offer. For a minimal shell, use "gluem.asm"
.inc "user.h"
.inc "err.h"
.inc "ascii.h"
.inc "blkdev.h"
.inc "fs.h"
jp	init

.inc "core.asm"
.inc "lib/util.asm"
.inc "lib/parse.asm"
.inc "lib/args.asm"
.equ	SHELL_RAMSTART	USER_RAMSTART
.equ	SHELL_EXTRA_CMD_COUNT	9
.inc "shell/main.asm"
.dw	blkBselCmd, blkSeekCmd, blkLoadCmd, blkSaveCmd
.dw	fsOnCmd, flsCmd, fnewCmd, fdelCmd, fopnCmd

.inc "lib/ari.asm"
.inc "lib/fmt.asm"
.inc "shell/blkdev.asm"
.inc "shell/fs.asm"

.equ	PGM_RAMSTART		SHELL_RAMEND
.equ	PGM_CODEADDR		USER_CODE
.inc "shell/pgm.asm"

init:
	call	shellInit
	ld	hl, pgmShellHook
	ld	(SHELL_CMDHOOK), hl
	jp	shellLoop

USER_RAMSTART:
