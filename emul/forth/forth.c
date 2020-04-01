#include <stdint.h>
#include <stdio.h>
#include <unistd.h>
#include <termios.h>
#include "../emul.h"
#include "forth1-bin.h"

// in sync with glue.asm
#define RAMSTART 0x900
#define STDIO_PORT 0x00
// This binary is also used for automated tests and those tests, when
// failing, send a non-zero value to RET_PORT to indicate failure
#define RET_PORT 0x01

static int running;
static FILE *fp;
static int retcode = 0;

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
    if (val == 0x04) { // CTRL+D
        running = 0;
    } else {
        putchar(val);
    }
}

static void iowr_ret(uint8_t val)
{
    retcode = val;
}


int main(int argc, char *argv[])
{
    bool tty = false;
    struct termios termInfo;
    if (argc == 2) {
        fp = fopen(argv[1], "r");
        if (fp == NULL) {
            fprintf(stderr, "Can't open %s\n", argv[1]);
            return 1;
        }
    } else if (argc == 1) {
        fp = stdin;
        tty = isatty(fileno(stdin));
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
    } else {
        fprintf(stderr, "Usage: ./forth [filename]\n");
        return 1;
    }
    Machine *m = emul_init();
    m->ramstart = RAMSTART;
    m->iord[STDIO_PORT] = iord_stdio;
    m->iowr[STDIO_PORT] = iowr_stdio;
    m->iowr[RET_PORT] = iowr_ret;
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

    if (tty) {
        printf("\nDone!\n");
        termInfo.c_lflag |= ECHO;
        termInfo.c_lflag |= ICANON;
        tcsetattr(0, TCSAFLUSH, &termInfo);
        emul_printdebug();
    }
    fclose(fp);
    return retcode;
}
