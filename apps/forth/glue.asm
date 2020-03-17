.inc "user.h"
jp	forthMain

.inc "core.asm"
.equ FORTH_RAMSTART RAMSTART
.inc "forth/main.asm"
.inc "forth/util.asm"
.inc "forth/stack.asm"
.inc "forth/dict.asm"
RAMSTART:
