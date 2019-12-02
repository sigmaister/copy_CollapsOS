#include <stdint.h>
#include <stdio.h>
#include "../emul.h"

/* runbin loads binary from stdin directly in memory address 0 then runs it
 * until it halts. The return code is the value of the register A at halt time.
 */

int main()
{
    Machine *m = emul_init();
    // read stdin in mem
    int i = 0;
    int c = getchar();
    while (c != EOF) {
        m->mem[i] = c & 0xff;
        i++;
        c = getchar();
    }
    if (!i) {
        fprintf(stderr, "No input, aborting\n");
        return 1;
    }
    emul_loop();
    return m->cpu.R1.br.A;
}

