# emul

This folder contains a couple of tools running under the [libz80][libz80]
emulator.

## Not real hardware

In the few emulated apps described below, we don't try to emulate real hardware
because the goal here is to facilitate userspace development.

These apps run on imaginary hardware and use many cheats to simplify I/Os.

For real hardware emulation (which helps developing drivers), see the `hw`
folder.

## Build

First, make sure that the `libz80` git submodule is checked out. If not, run
`git submodule init && git submodule update`.

After that, you can run `make` and it builds all applications.

## shell

Running `shell/shell` runs the BASIC shell in an emulated machine. The goal of
this machine is not to simulate real hardware, but rather to serve as a
development platform. What we do here is we emulate the z80 part, the 64K
memory space and then hook some fake I/Os to stdin, stdout and a small storage
device that is suitable for Collapse OS's filesystem to run on.

Through that, it becomes easier to develop userspace applications for Collapse
OS.

By default, the shell initialized itself with a CFS device containing the
contents of `cfsin/` at launch (it's packed on the fly). You can specify an
alternate CFS device file (it has to be packaed already) through the `-f` flag.

By default, the shell runs interactively, but you can also pipe contents through
stdin instead. The contents will be interpreted exactly as if you had typed it
yourself and the result will be spit in stdout (it includes your typed in
contents because the Collapse OS console echoes back every character that is
sent to it.). This feature is useful for automated tests in `tools/tests/shell`.

## zasm

`zasm/zasm` is `apps/zasm` wrapped in an emulator. It is quite central to the
Collapse OS project because it's used to assemble everything, including itself!

The program takes no parameter. It reads source code from stdin and spits
binary in stdout. It supports includes and had both `apps/` and `kernel` folder
packed into a CFS that was statically included in the executable at compile
time.

The file `zasm/zasm.bin` is a compiled binary for `apps/zasm/glue.asm` and
`zasm/kernel.bin` is a compiled binary for `tools/emul/zasm/glue.asm`. It is
used to bootstrap the assembling process so that no assembler other than zasm
is required to build Collapse OS.

This binary is fed to libz80 to produce the `zasm/zasm` "modern" binary and
once you have that, you can recreate `zasm/zasm.bin` and `zasm/kernel.bin`.

This is why it's included as a binary in the repo, but yes, it's redundant with
the source code.

Those binaries can be updated with the `make updatebootstrap` command. If they
are up-to date and that zasm isn't broken, this command should output the same
binary as before.

## avra

In the `zasm` folder, there's also `avra` which is a zasm compiled as an AVR
assembler. It works the same way as zasm except it expects AVR mnemonics and
spits AVR binaries.

## runbin

This is a very simple tool that reads binary z80 code from stdin, loads it in
memory starting at address 0 and then run the code until it halts. The exit
code of the program is the value of `A` when the program halts.

This is used for unit tests.

## Problems?

If the libz80-wrapped zasm executable works badly (hangs, spew garbage, etc.),
it's probably because you've broken your bootstrap binaries. They're easy to
mistakenly break. To verify if you've done that, look at your git status. If
`kernel.bin` or `zasm.bin` are modified, try resetting them and then run
`make clean all`. Things should go better afterwards.

If that doesn't work, there's also the nuclear option of `git reset --hard`
and `git clean -fxd`.

If that still doesn't work, it might be because the current commit you're on
is broken, but that is rather rare: the repo on Github is plugged on Travis
and it checks that everything is smooth.
