#include <stdint.h>
#include <stdio.h>
#include <unistd.h>
#include "../emul.h"
#ifdef STAGE2
#include "forth1-bin.h"
#else
#include "forth0-bin.h"
#endif

/* Staging binaries

The role of a stage executable is to compile definitions in a dictionary and
then spit the difference between the starting binary and the new binary.

That binary can then be grafted to an exiting Forth binary to augment its
dictionary.

We could, if we wanted, run only with the bootstrap binary and compile core
defs at runtime, but that would mean that those defs live in RAM. In may system,
RAM is much more constrained than ROM, so it's worth it to give ourselves the
trouble of compiling defs to binary.

*/

// When DEBUG is set, stage1 is a core-less forth that works interactively.
// Useful for... debugging!
// By the way: there's a double-echo in stagedbg. It's normal. Don't panic.

//#define DEBUG
// in sync with glue.asm
#define RAMSTART 0x840
#define STDIO_PORT 0x00
// To know which part of RAM to dump, we listen to port 2, which at the end of
// its compilation process, spits its HERE addr to port 2 (MSB first)
#define HERE_PORT 0x02

static int running;
// We support double-pokes, that is, a first poke to tell where to start the
// dump and a second one to tell where to stop. If there is only one poke, it's
// then ending HERE and we start at sizeof(KERNEL).
static uint16_t start_here = 0;
static uint16_t end_here = 0;

static uint8_t iord_stdio()
{
    int c = getc(stdin);
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

static void iowr_here(uint8_t val)
{
    start_here <<=8;
    start_here |= (end_here >> 8);
    end_here <<= 8;
    end_here |= val;
}

int main(int argc, char *argv[])
{
    Machine *m = emul_init();
    m->ramstart = RAMSTART;
    m->iord[STDIO_PORT] = iord_stdio;
    m->iowr[STDIO_PORT] = iowr_stdio;
    m->iowr[HERE_PORT] = iowr_here;
    // initialize memory
    for (int i=0; i<sizeof(KERNEL); i++) {
        m->mem[i] = KERNEL[i];
    }

    // Our binaries don't have their LATEST offset set yet. We do this
    // on the fly, which is the simplest way to proceed ( bash script to update
    // LATEST after compilation is too simplicated )
    m->mem[0x08] = sizeof(KERNEL) & 0xff;
    m->mem[0x09] = sizeof(KERNEL) >> 8;

    // Run!
    running = 1;

    while (running && emul_step());

#ifndef DEBUG
    // We're done, now let's spit dict data
    if (start_here == 0) {
        start_here = sizeof(KERNEL);
    }
    for (int i=start_here; i<end_here; i++) {
        putchar(m->mem[i]);
    }
#endif
    return 0;
}

