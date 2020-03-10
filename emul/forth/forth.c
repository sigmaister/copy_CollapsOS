#include <stdint.h>
#include <stdio.h>
#include <unistd.h>
#include <termios.h>
#include "../emul.h"
#include "forth-bin.h"

// in sync with glue.asm
#define RAMSTART 0x2000
#define STDIO_PORT 0x00

static int running;

static uint8_t iord_stdio()
{
    int c = getchar();
    if (c == EOF) {
        running = 0;
    }
    return (uint8_t)c;
}

static void iowr_stdio(uint8_t val)
{
    if (val == 0x04) { // CTRL+D
        running = 0;
    } else {
        putchar(val);
    }
}

int main(int argc, char *argv[])
{
    bool tty = isatty(fileno(stdin));
    struct termios termInfo;
    if (tty) {
        // Turn echo off: the shell takes care of its own echoing.
        if (tcgetattr(0, &termInfo) == -1) {
            printf("Can't setup terminal.\n");
            return 1;
        }
        termInfo.c_lflag &= ~ECHO;
        termInfo.c_lflag &= ~ICANON;
        tcsetattr(0, TCSAFLUSH, &termInfo);
    }

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

    if (tty) {
        printf("Done!\n");
        termInfo.c_lflag |= ECHO;
        termInfo.c_lflag |= ICANON;
        tcsetattr(0, TCSAFLUSH, &termInfo);
        emul_printdebug();
    }
    return 0;
}
