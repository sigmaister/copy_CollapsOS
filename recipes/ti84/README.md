# TI-84+

**This is a work-in-progress, this is far from complete.**

## Recipe

This recipe gets the Collapse OS shell to run on the TI-84+, using its LCD
screen as output and its builtin keyboard as input.

## Build the ROM

Running `make` will result in `os.rom` being created.

## Emulate through z80e

[KnightOS][knightos] has a handy emulator, [z80e][z80e] for TI calculators and
it also emulates the screen. It is recommended to use this tool.

Once z80e is installed (build it with SDL support) and `os.rom` is created,
you can run the emulator with:

    z80e-sdl -d TI84p --no-rom-check os.rom

You will start with a blank screen, it's normal, you haven't pressed the "ON"
key yet. This key is mapped to F12 in the emulator. Once you press it, the
Collapse OS prompt will appear.

**WIP: the keyboard does nothing else than halting the CPU for now.**

## Upload to the calculator

**WARNING: the instructions below will wipe all the contents of your calculator,
including TI-OS.**

To send your ROM to the calculator, you'll need two more tools:
[mktiupgrade][mktiupgrade] and [tilp][tilp].

Once you have them, you need to place your calculator in "bootloader mode",
that is, in a mode where it's ready to receive a new binary from its USB cable.
To do that you need to:

1. Shut down the calculator by removing one of the battery.
2. Hold the DEL key
3. But the battery back.
4. A "Waiting... Please install operating system now" message will appear.

Once this is done, you can plug the USB cable in your computer and run
`make send`. This will create an "upgrade file" with `mktiupgrade` and then
push that upgrade file with `tilp`. `tilp` will prompt you at some point.
Press "1" to continue.

When this is done, you can press the ON button to see Collapse OS' prompt!

[knightos]: https://knightos.org/
[z80e]: https://github.com/KnightOS/z80e
[mktiupgrade]: https://github.com/KnightOS/mktiupgrade
[tilp]: http://lpg.ticalc.org/prj_tilp/
