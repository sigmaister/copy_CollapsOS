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

* A "classic" RC2014 with Serial I/O
* [Forth's stage 2 binary][stage2]
* [romwrite][romwrite] and its specified dependencies
* [GNU screen][screen]
* A FTDI-to-TTL cable to connect to the Serial I/O module

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

Note that this method is slow and clunky, but before long, you won't be using
it anymore. Writing to an EEPROM is much easier and faster from a RC2014
running Collapse OS, so once you have that first Collapse OS ROM, you'll be
much better equipped for further toying around (unless, of course, you already
had tools to write to EEPROM. In which case, you'll be ignoring this section
altogether).

### Running

Put the AT28 in the ROM module, don't forget to set the A14 jumper high, then
power the thing up. Connect the FTDI-to-TTL cable to the Serial I/O module and
identify the tty bound to it (in my case, `/dev/ttyUSB0`). Then:

    screen /dev/ttyUSB0 115200

Press the reset button on the RC2014 to have Forth begin its bootstrap process.
Note that it has to build more than half of itself from source. It takes about
30 seconds to complete.

Once bootstrapping is done you should see the Collapse OS prompt. That's a full
Forth interpreter. You can have fun right now.

However, that long boot time is kinda annoying. Moreover, that bootstrap code
being in source form takes precious space from our 8K ROM. That brings us to
building stage 2.

### Building stage 2

You're about to learn a lot about this platform and its self-bootstrapping
nature, but its a bumpy ride. Grab something. Why not a beer?

Our stage 1 prompt is the result of Forth's inner core interpreting the source
code of the Full Forth, which was appended to the binary inner core in ROM.
This results in a compiled dictionary, in RAM, at address 0x8000+system RAM.

Unfortunately, this compiled dictionary isn't usable as-is. Offsets compiled in
there are compiled based on a 0x8000-or-so base offset. What we need is a
0xa00-or-so base offset, that is, something suitable to be appended to the boot
binary, in ROM, in binary form.

We can't simply adjust offsets. For complicated reasons, that can't be reliably
done. We have to re-interpret that same source code, but from a ROM offset. But
how are we going to do that? After all, ROM is called ROM for a reason.

Memory maps.

What we're going to do is to set up a memory map targeting our ROM and point it
to our RAM. Then we can recompile the source as if we were in ROM, right after
our boot binary. Forth won't ever notice it's actually in RAM.

Alright, let's do this. First, let's have a look around. Where is the end of
our boot binary? To know, find the word ";", which is the last word of icore:

    > ' ; .X
    097d>
    > 64 0x0970 DUMP
    :70 0035 0958 00da ff43 .5.X...C
    :78 003b 3500 810e 0020 .;5....
    :80 0043 0093 07f4 03ef .C......
    :88 0143 005f 0f00 0131 .C._...1
    :90 3132 2052 414d 2b20 12 RAM+
    :98 4845 5245 2021 0a20 HERE !.
    :a0 3a20 4840 2048 4552 : H@ HER
    :a8 4520 4020 3b0a 203a E @ ;. :

See that `_` at 0x98b? That's the name of our hook word. 4 bytes later is its
wordref. That's the end of our boot binary. 0x98f, that's an address to write
down.

Right after that is our appended source code. The first part is `pre.fs` and
can be ignored. What we want starts at the definition of the `H@` word, which
is at 0x9a0. Another address to write down.

So our memory map will target 0x98f. Where will we place it? It doesn't matter
much, we have plenty of RAM. Where's `HERE`?

    > H@ .X
    8c3f>

Alright, let's go wide and use 0xa000 as our map destination. But before we do,
let's copy the content of our ROM into RAM because there's our source code
there and if we don't copy it before setting up the memory map, we'll shadow it.

Let's be lazy and don't even check where the source stop. Let's assume it stops
at 0x1fff, the end of the ROM.

    > 0x98f 0xa000 0x2000 0x98f - MOVE
    > 64 0xa000 DUMP
    :00 3131 3220 5241 4d2b 112 RAM+
    :08 2048 4552 4520 210a  HERE !.
    :10 203a 2048 4020 4845  : H@ HE
    :18 5245 2040 203b 0a20 RE @ ;.
    :20 3a20 2d5e 2053 5741 : -^ SWA
    :28 5020 2d20 3b0a 203a P - ;. :
    :30 205b 2049 4e54 4552  [ INTER
    :38 5052 4554 2031 2046 PRET 1 F

Looks fine. Now, let's create a memory map. A memory map word is rather simple.
It is called before each `@/C@/!/C!` operation and is given the opportunity to
tweak the address on PSP's TOS. Let's go with our map:

    > : MMAP
    DUP 0x98f < IF EXIT THEN
    DUP 0x1fff > IF EXIT THEN
    [ 0xa000 0x98f - LITN ] +
    ;
    > 0x98e MMAP .X
    098e> 0x98f MMAP .X
    a000> 0xabc MMAP .X
    a12b> 0x1fff MMAP .X
    b66e> 0x2000 MMAP .X
    2000>

This looks good. Let's apply it for real:

    > ' MMAP (mmap*) !
    > 64 0x980 DUMP

    :80 0043 0093 07f4 03ef .C......
    :88 0143 005f 0f00 0131 .C._...1
    :90 3132 2052 414d 2b20 12 RAM+
    :98 4845 5245 2021 0a20 HERE !.
    :a0 3a20 4840 2048 4552 : H@ HER
    :a8 4520 4020 3b0a 203a E @ ;. :
    :b0 202d 5e20 5357 4150  -^ SWAP
    :b8 202d 203b 0a20 3a20  - ;. :

But how do we know that it really works? Because we can write in ROM!

    > 'X' 0x98f !
    > 64 0x980 DUMP

    :80 0043 0093 07f4 03ef .C......
    :88 0143 005f 0f00 0131 .C._...X
    :90 0032 2052 414d 2b20 .2 RAM+
    :98 4845 5245 2021 0a20 HERE !.
    :a0 3a20 4840 2048 4552 : H@ HER
    :a8 4520 4020 3b0a 203a E @ ;. :
    :b0 202d 5e20 5357 4150  -^ SWAP
    :b8 202d 203b 0a20 3a20  - ;. :
    > 64 0xa000 DUMP

    :00 5800 3220 5241 4d2b X.2 RAM+
    :08 2048 4552 4520 210a  HERE !.
    :10 203a 2048 4020 4845  : H@ HE
    :18 5245 2040 203b 0a20 RE @ ;.
    :20 3a20 2d5e 2053 5741 : -^ SWA
    :28 5020 2d20 3b0a 203a P - ;. :
    :30 205b 2049 4e54 4552  [ INTER
    :38 5052 4554 2031 2046 PRET 1 F

We're now ready for a re-bootstrap. Here's what we're gonna do:

1. Bring `CURRENT` and `HERE` back to `0x98f`.
2. Set `CINPTR` to `icore`'s `(c<)`.

`(c<)` word is the main input of the interpreter. Right now, your `(c<)` comes
from the `readln` unit, which makes the main `INTERPRET` loop wait for your
keystrokes before interpreting your words.

But this can be changed. At the moment where we change `CINPTR`, the interpret
loop will start reading from it, so we'll lose control. That is why we must
prepare things carefully before that. We'll re-gain control at the end of the
bootstrap source, in `run.fs`, where `(c<)` is set to `readln`'s `(c<)`

`(c<)` word is the main input of the interpreter. Right now, your `(c<)` comes
from the `readln` unit, which makes the main `INTERPRET` loop wait for your
keystrokes before interpreting your words.

But this can be changed. At the moment where we change `CINPTR`, the interpret
loop will start reading from it, so we'll lose control. That is why we must
prepare things carefully before that. We'll re-gain control at the end of the
bootstrap source, in `run.fs`, where `(c<)` is set to `readln`'s `(c<)`.

At this moment, `icore`'s `(c<)` is shadowed by `readln`, but at the moment
`CURRENT` changes, it will be accessible again. However, this all has to change
in one shot, so we need to prepare a compiled word for it if we don't want to
lose access to our interpret loop in the middle of our operation.

    > : KAWABUNGA!
    ( 60 == (c<) pointer )
    0x9a0 0x60 RAM+ !
    0x98f CURRENT !
    0x98f HERE !
    ( 0c == CINPTR )
    (find) (c<) DROP 0x0c RAM+ !
    ;

Ready? Set? KAWABUNGA!

TODO: make this work...

[rc2014]: https://rc2014.co.uk
[romwrite]: https://github.com/hsoft/romwrite
[stage2]: ../../emul
[screen]: https://www.gnu.org/software/screen/
