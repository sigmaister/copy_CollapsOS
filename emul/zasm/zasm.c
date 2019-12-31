#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <libgen.h>
#include "../emul.h"
#include "../../tools/cfspack/cfs.h"
#include "kernel-bin.h"
#ifdef AVRA
#include "avra-bin.h"
#else
#include "zasm-bin.h"
#endif

/* zasm reads from a specified blkdev, assemble the file and writes the result
 * in another specified blkdev. In our emulator layer, we use stdin and stdout
 * as those specified blkdevs.
 *
 * This executable takes two arguments. Both are optional, but you need to
 * specify the first one if you want to get to the second one.
 * The first one is the value to send to z80-zasm's 3rd argument (the initial
 * .org). Defaults to '00'.
 * The second one is the path to a .cfs file to use for includes.
 *
 * Because the input blkdev needs support for Seek, we buffer it in the emulator
 * layer.
 *
 * Memory layout:
 *
 * 0x0000 - 0x3fff: ROM code from zasm_glue.asm
 * 0x4000 - 0x47ff: RAM for kernel and stack
 * 0x4800 - 0x57ff: Userspace code
 * 0x5800 - 0xffff: Userspace RAM
 *
 * I/O Ports:
 *
 * 0 - stdin / stdout
 * 1 - When written to, rewind stdin buffer to the beginning.
 */

// in sync with zasm_glue.asm
#define USER_CODE 0x4800
#define STDIO_PORT 0x00
#define STDIN_SEEK_PORT 0x01
#define FS_DATA_PORT 0x02
#define FS_SEEK_PORT 0x03
#define STDERR_PORT 0x04

// Other consts
#define STDIN_BUFSIZE 0x8000
// When defined, we dump memory instead of dumping expected stdout
//#define MEMDUMP
//#define DEBUG
// By default, we don't spit what zasm prints. Too noisy. Define VERBOSE if
// you want to spit this content to stderr.
//#define VERBOSE
#define MAX_FSDEV_SIZE 0x80000

// STDIN buffer, allows us to seek and tell
static uint8_t inpt[STDIN_BUFSIZE];
static int inpt_size;
static int inpt_ptr;
static uint8_t middle_of_seek_tell = 0;

static uint8_t fsdev[MAX_FSDEV_SIZE] = {0};
static uint32_t fsdev_ptr = 0;
static uint8_t fsdev_seek_tell_cnt = 0;

static uint8_t iord_stdio()
{
    if (inpt_ptr < inpt_size) {
        return inpt[inpt_ptr++];
    } else {
        return 0;
    }
}

static uint8_t iord_stdin_seek()
{
    if (middle_of_seek_tell) {
        middle_of_seek_tell = 0;
        return inpt_ptr & 0xff;
    } else {
#ifdef DEBUG
        fprintf(stderr, "tell %d\n", inpt_ptr);
#endif
        middle_of_seek_tell = 1;
        return inpt_ptr >> 8;
    }
}

static uint8_t iord_fsdata()
{
    if (fsdev_ptr < MAX_FSDEV_SIZE) {
        return fsdev[fsdev_ptr++];
    } else {
        return 0;
    }
}

static uint8_t iord_fsseek()
{
    if (fsdev_seek_tell_cnt != 0) {
        return fsdev_seek_tell_cnt;
    } else if (fsdev_ptr >= MAX_FSDEV_SIZE) {
        return 1;
    } else {
        return 0;
    }
}

static void iowr_stdio(uint8_t val)
{
// When mem-dumping, we don't output regular stuff.
#ifndef MEMDUMP
    putchar(val);
#endif
}

static void iowr_stdin_seek(uint8_t val)
{
    if (middle_of_seek_tell) {
        inpt_ptr |= val;
        middle_of_seek_tell = 0;
#ifdef DEBUG
        fprintf(stderr, "seek %d\n", inpt_ptr);
#endif
    } else {
        inpt_ptr = (val << 8) & 0xff00;
        middle_of_seek_tell = 1;
    }
}

static void iowr_fsdata(uint8_t val)
{
    if (fsdev_ptr < MAX_FSDEV_SIZE) {
        fsdev[fsdev_ptr++] = val;
    }
}

static void iowr_fsseek(uint8_t val)
{
    if (fsdev_seek_tell_cnt == 0) {
        fsdev_ptr = val << 16;
        fsdev_seek_tell_cnt = 1;
    } else if (fsdev_seek_tell_cnt == 1) {
        fsdev_ptr |= val << 8;
        fsdev_seek_tell_cnt = 2;
    } else {
        fsdev_ptr |= val;
        fsdev_seek_tell_cnt = 0;
#ifdef DEBUG
        fprintf(stderr, "FS seek %d\n", fsdev_ptr);
#endif
    }
}

static void iowr_stderr(uint8_t val)
{
#ifdef VERBOSE
    fputc(val, stderr);
#endif
}

void usage()
{
    fprintf(stderr, "Usage: zasm [-o org] [include-dir-or-file...] < source > binary\n");
}

int main(int argc, char *argv[])
{
    char *init_org = "00";
    while (1) {
        int c = getopt(argc, argv, "o:");
        if (c < 0) {
            break;
        }
        switch (c) {
            case 'o':
                init_org = optarg;
                if (strlen(init_org) != 2) {
                    fprintf(stderr, "Initial org must be a two-character hex string");
                }
                break;
            default:
                usage();
                return 1;
        }
    }
    if (argc-optind > 0) {
        FILE *fp = fmemopen(fsdev, MAX_FSDEV_SIZE, "w");
        set_spit_stream(fp);
        char *patterns[4] = {"*.h", "*.asm", "*.bin", 0};
        for (int i=optind; i<argc; i++) {
            int res;
            if (is_regular_file(argv[i])) {
                // special case: just one file
                res = spitblock(argv[i], basename(argv[i]));
            } else {
                res = spitdir(argv[i], "", patterns);
            }
            if (res != 0) {
                fprintf(stderr, "Error while building the include CFS.\n");
                fclose(fp);
                return 1;
            }
        }
        fclose(fp);
    }
    Machine *m = emul_init();
    m->iord[STDIO_PORT] = iord_stdio;
    m->iord[STDIN_SEEK_PORT] = iord_stdin_seek;
    m->iord[FS_DATA_PORT] = iord_fsdata;
    m->iord[FS_SEEK_PORT] = iord_fsseek;
    m->iowr[STDIO_PORT] = iowr_stdio;
    m->iowr[STDIN_SEEK_PORT] = iowr_stdin_seek;
    m->iowr[FS_DATA_PORT] = iowr_fsdata;
    m->iowr[FS_SEEK_PORT] = iowr_fsseek;
    m->iowr[STDERR_PORT] = iowr_stderr;
    // initialize memory
    for (int i=0; i<sizeof(KERNEL); i++) {
        m->mem[i] = KERNEL[i];
    }
    for (int i=0; i<sizeof(USERSPACE); i++) {
        m->mem[i+USER_CODE] = USERSPACE[i];
    }
    // glue.asm knows that it needs to fetch these arguments at this address.
    m->mem[0xff00] = init_org[0];
    m->mem[0xff01] = init_org[1];
    // read stdin in buffer
    inpt_size = 0;
    inpt_ptr = 0;
    int c = getchar();
    while (c != EOF) {
        inpt[inpt_ptr] = c & 0xff;
        inpt_ptr++;
        if (inpt_ptr == STDIN_BUFSIZE) {
            break;
        }
        c = getchar();
    }
    inpt_size = inpt_ptr;
    inpt_ptr = 0;

    emul_loop();
#ifdef MEMDUMP
    for (int i=0; i<0x10000; i++) {
        putchar(mem[i]);
    }
#endif
    fflush(stdout);
    int res = m->cpu.R1.br.A;
    if (res != 0) {
        int lineno = m->cpu.R1.wr.HL;
        int inclineno = m->cpu.R1.wr.DE;
        if (inclineno) {
            fprintf(
                stderr,
                "Error %d on line %d, include line %d\n",
                res,
                lineno,
                inclineno);
        } else {
            fprintf(stderr, "Error %d on line %d\n", res, lineno);
        }
    }
    return res;
}

