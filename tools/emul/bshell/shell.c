#include <stdint.h>
#include <stdio.h>
#include <termios.h>
#include "../emul.h"
#include "shell-bin.h"

/* Collapse OS shell with filesystem
 *
 * On startup, if "cfsin" directory exists, it packs it as a afke block device
 * and loads it in. Upon halting, unpcks the contents of that block device in
 * "cfsout" directory.
 *
 * Memory layout:
 *
 * 0x0000 - 0x3fff: ROM code from shell.asm
 * 0x4000 - 0x4fff: Kernel memory
 * 0x5000 - 0xffff: Userspace
 *
 * I/O Ports:
 *
 * 0 - stdin / stdout
 * 1 - Filesystem blockdev data read/write. Reads and write data to the address
 *     previously selected through port 2
 */

//#define DEBUG
#define MAX_FSDEV_SIZE 0x20000

// in sync with glue.asm
#define RAMSTART 0x2000
#define STDIO_PORT 0x00
#define FS_DATA_PORT 0x01
// Controls what address (24bit) the data port returns. To select an address,
// this port has to be written to 3 times, starting with the MSB.
// Reading this port returns an out-of-bounds indicator. Meaning:
// 0 means addr is within bounds
// 1 means that we're equal to fsdev size (error for reading, ok for writing)
// 2 means more than fsdev size (always invalid)
// 3 means incomplete addr setting
#define FS_ADDR_PORT 0x02

static uint8_t fsdev[MAX_FSDEV_SIZE] = {0};
static uint32_t fsdev_size = 0;
static uint32_t fsdev_ptr = 0;
// 0 = idle, 1 = received MSB (of 24bit addr), 2 = received middle addr
static int  fsdev_addr_lvl = 0;
static int running;

static uint8_t iord_stdio()
{
    int c = getchar();
    if (c == EOF) {
        running = 0;
    }
    return (uint8_t)c;
}

static uint8_t iord_fsdata()
{
    if (fsdev_addr_lvl != 0) {
        fprintf(stderr, "Reading FSDEV in the middle of an addr op (%d)\n", fsdev_ptr);
        return 0;
    }
    if (fsdev_ptr < fsdev_size) {
#ifdef DEBUG
        fprintf(stderr, "Reading FSDEV at offset %d\n", fsdev_ptr);
#endif
        return fsdev[fsdev_ptr];
    } else {
        // don't warn when ==, we're not out of bounds, just at the edge.
        if (fsdev_ptr > fsdev_size) {
            fprintf(stderr, "Out of bounds FSDEV read at %d\n", fsdev_ptr);
        }
        return 0;
    }
}

static uint8_t iord_fsaddr()
{
    if (fsdev_addr_lvl != 0) {
        return 3;
    } else if (fsdev_ptr > fsdev_size) {
        fprintf(stderr, "Out of bounds FSDEV addr request at %d / %d\n", fsdev_ptr, fsdev_size);
        return 2;
    } else if (fsdev_ptr == fsdev_size) {
        return 1;
    } else {
        return 0;
    }
}

static void iowr_stdio(uint8_t val)
{
    if (val == 0x04) { // CTRL+D
        running = 0;
    } else {
        putchar(val);
    }
}

static void iowr_fsdata(uint8_t val)
{
    if (fsdev_addr_lvl != 0) {
        fprintf(stderr, "Writing to FSDEV in the middle of an addr op (%d)\n", fsdev_ptr);
        return;
    }
    if (fsdev_ptr < fsdev_size) {
#ifdef DEBUG
        fprintf(stderr, "Writing to FSDEV (%d)\n", fsdev_ptr);
#endif
        fsdev[fsdev_ptr] = val;
    } else if ((fsdev_ptr == fsdev_size) && (fsdev_ptr < MAX_FSDEV_SIZE)) {
        // We're at the end of fsdev, grow it
        fsdev[fsdev_ptr] = val;
        fsdev_size++;
#ifdef DEBUG
        fprintf(stderr, "Growing FSDEV (%d)\n", fsdev_ptr);
#endif
    } else {
        fprintf(stderr, "Out of bounds FSDEV write at %d\n", fsdev_ptr);
    }
}

static void iowr_fsaddr(uint8_t val)
{
    if (fsdev_addr_lvl == 0) {
        fsdev_ptr = val << 16;
        fsdev_addr_lvl = 1;
    } else if (fsdev_addr_lvl == 1) {
        fsdev_ptr |= val << 8;
        fsdev_addr_lvl = 2;
    } else {
        fsdev_ptr |= val;
        fsdev_addr_lvl = 0;
    }
}

int main()
{
    // Setup fs blockdev
    FILE *fp = popen("../cfspack/cfspack cfsin", "r");
    if (fp != NULL) {
        printf("Initializing filesystem\n");
        int i = 0;
        int c = fgetc(fp);
        while (c != EOF) {
            fsdev[i] = c & 0xff;
            i++;
            c = fgetc(fp);
        }
        fsdev_size = i;
        pclose(fp);
    } else {
        printf("Can't initialize filesystem. Leaving blank.\n");
    }

    // Turn echo off: the shell takes care of its own echoing.
    struct termios termInfo;
    if (tcgetattr(0, &termInfo) == -1) {
        printf("Can't setup terminal.\n");
        return 1;
    }
    termInfo.c_lflag &= ~ECHO;
    termInfo.c_lflag &= ~ICANON;
    tcsetattr(0, TCSAFLUSH, &termInfo);


    Machine *m = emul_init();
    m->ramstart = RAMSTART;
    m->iord[STDIO_PORT] = iord_stdio;
    m->iord[FS_DATA_PORT] = iord_fsdata;
    m->iord[FS_ADDR_PORT] = iord_fsaddr;
    m->iowr[STDIO_PORT] = iowr_stdio;
    m->iowr[FS_DATA_PORT] = iowr_fsdata;
    m->iowr[FS_ADDR_PORT] = iowr_fsaddr;
    // initialize memory
    for (int i=0; i<sizeof(KERNEL); i++) {
        m->mem[i] = KERNEL[i];
    }
    // Run!
    running = 1;

    while (running && emul_step());

    printf("Done!\n");
    termInfo.c_lflag |= ECHO;
    termInfo.c_lflag |= ICANON;
    tcsetattr(0, TCSAFLUSH, &termInfo);
    emul_printdebug();
    return 0;
}
