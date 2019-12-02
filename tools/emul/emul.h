#include <stdint.h>
#include <stdbool.h>
#include "libz80/z80.h"

typedef uint8_t (*IORD) ();
typedef void (*IOWR) (uint8_t data);

typedef struct {
    Z80Context cpu;
    uint8_t mem[0x10000];
    // Set to non-zero to specify where ROM ends. Any memory write attempt
    // below ramstart will trigger a warning.
    uint16_t ramstart;
    // Array of 0x100 function pointers to IO read and write routines. Leave to
    // NULL when IO port is unhandled.
    IORD iord[0x100];
    IOWR iowr[0x100];
} Machine;

Machine* emul_init();
bool emul_step();
void emul_loop();
