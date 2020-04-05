# RC2014

The [RC2014][rc2014] is a nice and minimal z80 system that has the advantage
of being available in an assembly kit. Assembling it yourself involves quite a
bit of soldering due to the bus system. However, one very nice upside of that
bus system is that each component is isolated and simple.

The machine used in this recipe is the "Classic" RC2014 with an 8k ROM module
, 32k of RAM, a 7.3728Mhz clock and a serial I/O.

The ROM module being supplied in the assembly kit is an EPROM, not EEPROM, so
you can't install Collapse OS on it. You'll have to supply your own.

There are many options around to boot arbitrary sources. What was used in this
recipe was a AT28C64B EEPROM module. I chose it because it's compatible with
the 8k ROM module which is very convenient. If you do the same, however, don't
forget to set the A14 jumper to high because what is the A14 pin on the AT27
ROM module is the WE pin on the AT28! Setting the jumper high will keep is
disabled.

## Related recipes

This recipe is for installing a minimal Collapse OS system on the RC2014. There
are other recipes related to the RC2014:

* [Writing to a AT28 from Collapse OS](eeprom/README.md)
* [Accessing a MicroSD card](sdcard/README.md)
* [Assembling binaries](zasm/README.md)
* [Interfacing a PS/2 keyboard](ps2/README.md)

## Recipe

The goal is to have the shell running and accessible through the Serial I/O.

You'll need specialized tools to write data to the AT28 EEPROM. There seems to
be many devices around made to write in flash and EEPROM modules, but being in
a "understand everything" mindset, I [built my own][romwrite]. This is the
device I use in this recipe.

### Gathering parts

* [Forth's stage 2 binary][stage2]
* [romwrite][romwrite] and its specified dependencies
* [GNU screen][screen]
* A FTDI-to-TTL cable to connect to the Serial I/O module of the RC2014
* (Optional) RC2014's Digital I/O module

### Configure your build

Modules used in this build are configured through the `conf.fs` file in this
folder. There isn't much to configure, but it's there.

### Build stage 1

Self-bootstrapping is in Forth's DNA, which is really nice, but it makes
cross-compiling a bit tricky. It's usually much easier to bootstrap a Forth
from itself than trying to compile it from a foreign host.

This makes us adopt a 2 stages strategy. A tiny core is built from a foreign
host, and then we run that tiny core on the target machine and let it bootstrap
itself, then write our full interpreter binary.

We could have this recipe automate that 2 stage build process all automatically,
but that would rob you of all your fun, right? Instead, we'll run that 2nd
stage on the RC2014 itself!

To build your stage 1, run `make` in this folder, this will yield `os.bin`.
This will contain that tiny core and, appended to it, the Forth source code it
needs to run to bootstrap itself. When it's finished bootstrapping, you will
get a prompt to a full Forth interpreter.

### Emulate

The Collapse OS project includes a RC2014 emulator suitable for this image.
You can invoke it with `make emul`. See `emul/hw/rc2014/README.md` for details.

### Write to the ROM

Plug your romwrite atmega328 to your computer and identify the tty bound to it.
In my case (arduino uno), it's `/dev/ttyACM0`. Then:

    screen /dev/ttyACM0 9600
    CTRL-A + ":quit"
    cat rom.bin | pv -L 10 > /dev/ttyACM0

See romwrite's README for details about these commands.

### Running

Put the AT28 in the ROM module, don't forget to set the A14 jumper high, then
power the thing up. Connect the FTDI-to-TTL cable to the Serial I/O module and
identify the tty bound to it (in my case, `/dev/ttyUSB0`). Then:

    screen /dev/ttyUSB0 115200

Press the reset button on the RC2014 to have Forth begin its bootstrap process.
Note that it has to build more than half of itself from source. It takes a
while about 30 seconds to complete.

Once bootstrapping is done, you'll get a and you should see the Collapse OS
prompt. That's a full Forth interpreter. You can have fun right now.

However, that long boot time is kinda annoying. Moreover, that bootstrap code
being in source form takes precious space from our 8K ROM. We already have our
compiled dictionary in memory. All we need to have a instant-booting Forth is
to combine our stage1 with our compiled dict in memory, after some relinking.

TODO: write this, do this.

[rc2014]: https://rc2014.co.uk
[romwrite]: https://github.com/hsoft/romwrite
[stage2]: ../../emul
[screen]: https://www.gnu.org/software/screen/
