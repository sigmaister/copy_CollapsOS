#include <stdint.h>
#include <stdio.h>
#include <unistd.h>
#include "../emul.h"
#include "forth0-bin.h"

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
#define RAMSTART 0x900
#define STDIO_PORT 0x00
// To know which part of RAM to dump, we listen to port 2, which at the end of
// its compilation process, spits its HERE addr to port 2 (MSB first)
#define HERE_PORT 0x02

static int running;
static uint16_t ending_here = 0;

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
    ending_here <<= 8;
    ending_here |= val;
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
    // Run!
    running = 1;

    while (running && emul_step());

#ifndef DEBUG
    // We're done, now let's spit dict data
    fprintf(stderr, "hey, %x\n", ending_here);
    for (int i=sizeof(KERNEL); i<ending_here; i++) {
        putchar(m->mem[i]);
    }
#endif
    return 0;
}

