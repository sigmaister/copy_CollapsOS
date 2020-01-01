# RC2014 emulation

This emulates a RC2014 classic with 8K of ROM, 32K of RAM and an ACIA hooked to
stdin/stdout.

Run `make` to build.

## Usage

Run `./classic /path/to/rom` (for example, `os.bin` from RC2014's recipe).
Serial I/O is hooked to stdin/stdout. `CTRL+D` to quit.
