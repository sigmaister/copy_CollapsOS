#include <stdint.h>
#include <stdio.h>
#include <unistd.h>
#include "../emul.h"
#include "forth0-bin.h"

/* Stage 1

The role of the stage 1 executable is to start from a bare Forth executable
(stage 0) that will compile core non-native definitions into binary form and
append this to existing bootstrap binary to form our final Forth bin.

We could, if we wanted, run only with the bootstrap binary and compile core
defs at runtime, but that would mean that those defs live in RAM. In may system,
RAM is much more constrained than ROM, so it's worth it to give ourselves the
trouble of compiling defs to binary.

This stage 0 executable has to be layed out in a particular manner: HERE must
directly follow executable's last byte so that we don't waste spce and also
that wordref offsets correspond.
*/

// When DEBUG is set, stage1 is a core-less forth that works interactively.
// Useful for... debugging!
// By the way: there's a double-echo in stagedbg. It's normal. Don't panic.

//#define DEBUG
// in sync with glue.asm
#define RAMSTART 0x900
#define STDIO_PORT 0x00
// In sync with glue code. This way, we can know where HERE was when we stopped
// running
#define HERE 0xe700
// We also need to know what CURRENT is so we can write our first two bytes
#define CURRENT 0xe702

static int running;
static FILE *fp;

static uint8_t iord_stdio()
{
    int c = getc(fp);
    if (c == EOF) {
        running = 0;
    }
    return (uint8_t)c;
}

static void iowr_stdio(uint8_t val)
{
    // we don't output stdout in stage0
#ifdef DEBUG
    // ... unless we're in DEBUG mode!
    putchar(val);
#endif
}

int main(int argc, char *argv[])
{
#ifdef DEBUG
    fp = stdin;
#else
    if (argc == 2) {
        fp = fopen(argv[1], "r");
        if (fp == NULL) {
            fprintf(stderr, "Can't open %s\n", argv[1]);
            return 1;
        }
    } else {
        fprintf(stderr, "Usage: ./stage0 filename\n");
        return 1;
    }
#endif
    Machine *m = emul_init();
    m->ramstart = RAMSTART;
    m->iord[STDIO_PORT] = iord_stdio;
    m->iowr[STDIO_PORT] = iowr_stdio;
    // initialize memory
    for (int i=0; i<sizeof(KERNEL); i++) {
        m->mem[i] = KERNEL[i];
    }
    // Run!
    running = 1;

    while (running && emul_step());

    fclose(fp);

#ifndef DEBUG
    // We're done, now let's spit dict data
    // let's start with LATEST spitting.
    putchar(m->mem[CURRENT]);
    putchar(m->mem[CURRENT+1]);
    uint16_t here = m->mem[HERE] + (m->mem[HERE+1] << 8);
    for (int i=sizeof(KERNEL); i<here; i++) {
        putchar(m->mem[i]);
    }
#endif
    return 0;
}

