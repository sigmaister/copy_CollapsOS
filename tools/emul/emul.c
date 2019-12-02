/* Common code between shell, zasm and runbin.

They all run on the same kind of virtual machine: A z80 CPU, 64K of RAM/ROM.
*/

#include <string.h>
#include "emul.h"

static Machine m;

static uint8_t io_read(int unused, uint16_t addr)
{
    addr &= 0xff;
    IORD fn = m.iord[addr];
    if (fn != NULL) {
        return fn();
    } else {
        fprintf(stderr, "Out of bounds I/O read: %d\n", addr);
        return 0;
    }
}

static void io_write(int unused, uint16_t addr, uint8_t val)
{
    addr &= 0xff;
    IOWR fn = m.iowr[addr];
    if (fn != NULL) {
        fn(val);
    } else {
        fprintf(stderr, "Out of bounds I/O write: %d / %d (0x%x)\n", addr, val, val);
    }
}

static uint8_t mem_read(int unused, uint16_t addr)
{
    return m.mem[addr];
}

static void mem_write(int unused, uint16_t addr, uint8_t val)
{
    if (addr < m.ramstart) {
        fprintf(stderr, "Writing to ROM (%d)!\n", addr);
    }
    m.mem[addr] = val;
}

Machine* emul_init()
{
    memset(m.mem, 0, 0x10000);
    m.ramstart = 0;
    for (int i=0; i<0x100; i++) {
        m.iord[i] = NULL;
        m.iowr[i] = NULL;
    }
    Z80RESET(&m.cpu);
    m.cpu.memRead = mem_read;
    m.cpu.memWrite = mem_write;
    m.cpu.ioRead = io_read;
    m.cpu.ioWrite = io_write;
    return &m;
}


bool emul_step()
{
    if (!m.cpu.halted) {
        Z80Execute(&m.cpu);
        return true;
    } else {
        return false;
    }
}

void emul_loop()
{
    while (emul_step());
}
