.inc "user.h"
jp	forthMain

.inc "core.asm"
.inc "lib/util.asm"
.inc "lib/parse.asm"
.inc "lib/ari.asm"
.equ FORTH_RAMSTART RAMSTART
.inc "forth/main.asm"
.inc "forth/util.asm"
.inc "forth/stack.asm"
.inc "forth/dict.asm"
RAMSTART:
