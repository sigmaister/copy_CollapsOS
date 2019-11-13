# TI-84+

The TI-84+ is a machine with many advantages, one being that it's very popular.
It also has a lot of flash memory and RAM.

Its builtin keyboard and screen, however, are hard to use, especially the
screen. With a tiny font, the best we can get is a 24x10 console.

There is, however, a built-in USB controller that might prove very handy.

## Recipe

This recipe gets the Collapse OS shell to run on the TI-84+, using its LCD
screen as output and its builtin keyboard as input.

## Gathering parts

* [zasm][zasm]
* A TI-84+ (TI-83+ compatibility is being worked on. See issue #41)
* A USB cable
* [tilp][tilp]
* [mktiupgrade][mktiupgrade]
* Optional: [z80e][z80e] to emulate

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

See z80e's `KEYBINDINGS.md` file for details.

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

## Usage

The shell works like a normal shell, but with very tight screen space.

When pressing a "normal" key, it spits the symbol associated to it depending
on the current mode. In normal mode, it spits the digit/symbol. In Alpha mode,
it spits the letter. In Alpha+2nd, it spits the uppercase letter.

Special keys are Alpha and 2nd. Pressing them toggles the associated mode.
Alpha and 2nd mode don't persist for more than one character. After the
character is spit, mode reset to normal.

Pressing 2nd then Alpha will toggle the A-Lock mode, which is a persistent mode.
The A-Lock mode makes Alpha enabled all the time. While A-Lock mode is enabled,
you have to enable Alpha to spit a digit/symbol.

Simultaneous keypresses have undefined behavior. One of the keys will be
registered as pressed. Mode key don't work by simultaneously pressing them with
a "normal" key. The presses must be sequential.

Keys that aren't a digit, a letter, a symbol that is part of 7-bit ASCII or one
of the two mode key have no effect.

[zasm]: ../../tools/emul
[knightos]: https://knightos.org/
[z80e]: https://github.com/KnightOS/z80e
[mktiupgrade]: https://github.com/KnightOS/mktiupgrade
[tilp]: http://lpg.ticalc.org/prj_tilp/
