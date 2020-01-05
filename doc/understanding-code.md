# Understanding the code

One of the design goals of Collapse OS is that its code base should be easily
understandable in its entirety. Let's help with this with a little walthrough.
We use the basic `rc2014` recipe as a basis for the walkthrough.

This walkthrough assumes that you know z80 assembly. It is recommended that you
read code conventions in `CODE.md` first.

Code snippets aren't reproduced here. You have to follow along with code
listing.

## Power on

You have a RC2014 classic built with an EEPROM that has the recipe's binary on
it and you're linked to its serial I/O module. What happens when you power it
on and press the reset button (I've always had to press the reset button for
the RC2014 to power on properly. I don't know why. Must be some tricky sync
issue with the components)?

A freshly booted Z80 starts executing address zero. That address is in your
glue code. The first thing it does is thus `jp init`. Initialization is handled
by `recipes/rc2014/glue.asm`.

As you can see, it's a fairly straightforward init. Stack at the end of RAM,
interrupt mode 1 (which we use for the ACIA), then individual module
initialization, and finally, BASIC's runloop.

## ACIA init

An Asynchronous Communication Interface Adaptor allows serial communication with
another ACIA (ref http://alanclements.org/serialio.html ). The RC2014 uses a
6850 ACIA IC and Collapse OS's `kernel/acia` module was written to interface
with this kind of IC.

For this module to work, it needs to be wired to the z80 but in a particular
manner (which oh! surprise, the RC2014's Serial I/O module is...): It should use
two ports, R/W. One for access to its status register and one for its access to
its data register. Also, its `INT` line should be wired to the z80 `INT` line
for interrupts to work.

I won't go into much detail about the wiring: the 6850 seems to have been
designed to be wired thus, so it would kind of be like stating the obvious.

`aciaInit` in `kernel/acia` is also straightforward. First, it initializes the
input buffer. This buffer is a circular buffer that is filled with high priority
during the interrupt handler at `aciaInt`. It's important that we process input
at high priority to be sure not to miss a byte (there is no buffer overrun
handling in `acia`. Unhandled data is simply lost).

That buffer will later be emptied by BASIC's main loop.

Once the input buffer is set up, all that is left is to set up the ACIA itself,
which is configurable through `ACIA_CTL`. Comments in the code are
self-explanatory. Make sure that you use serial config, on the other side, that
is compatible with this config there.

## BASIC init

Then comes `basInit` at `apps/basic/main`. This is a bigger app, so there is
more stuff to initialize, but still, it stays straightforward. I'm not going to
explain every line, but give you a recipe for understanding. Every variable as,
above its declaration line, a comment explaining what it does. Refer to it.

This init method is the first one we see that has sub-methods in it. To quickly
find where they live, be aware that the general convention in Collapse OS code
is to prefix every label with its module name. So, for example, `varInit` lives
in `apps/basic/var`.

You can also see, in the initialization of `BAS_FINDHOOK`, a common idiom: the
use of `unsetZ` (from `kernel/core`) as a noop that returns an error (in this
case, it just means "command not found").

## Sending the prompt

We're now entering `basStart`, which simply prints Collapse OS' prompt and then
enter its runloop. Let's examine what happens when we call `printstr` (from
`kernel/stdio`).

`printstr` itself is easy. It iterates over `(HL)` and calls `STDIO_PUTC` for
each char.

But what is `STDIO_PUTC`? It's a glue-defined routine. Let's go back to
`glue.asm`. You see that `.equ STDIO_PUTC aciaPutC` line is? Well, there you
have it. `call STDIO_PUTC`, in our context, is the exact equivalent of
`call aciaPutC`. Let's go see it.

Whew! it's straightforward! We do two things here: wait until the ACIA is ready
to transmit (if it's not, it means that it's still in the process of
transmitting the previous character we asked it to transmit), then send that
char straight to the data port.

## BASIC's runloop

Once the prompt is sent, we're entering BASIC's runloop at `basLoop`. This loops
forever.

The first thing it does is to wait for a line to be entered using
`stdioReadLine` from `kernel/stdio`. Let's see what this does.

Oh, this is a little less straightforward. This routine repeatedly calls
`STDIO_GETC` and puts the result in a stdio-specific buffer, after having echoed
back the received character so that the user sees what she types.

`STDIO_GETC` is blocking. It always returns a char.

As you can see in the glue unit, `STDIO_GETC` is mapped to `aciaGetC`. This
routine waits until the ACIA buffer has something in it. Once it does, it reads
one character from it and returns it.

Back to `stdioReadLine`, we check that we don't have special handling to do,
that is, end of line or deletion. If we don't, we echo back the char, advance
buffer pointer, wait for a new one.

If we receive a CR or LF, the line is complete, so we return to `basLoop` with
a null-terminated input line in `(HL)`.

I won't cover the processing of the line by BASIC because it's a bit long and
doesn't help holistic understanding very much, You can read the code.

Once the line is processed, that the associated command is found and called, we
go back the the beginning of the loop for another ride.

## When do we receive a character?

In the above section, we simply wait until the buffer has something in it. But
how will that happen? Through `aciaInt` interrupt.

When the ACIA receives a new character, it pulls the `INT` line low, which, in
interrupt mode 1, calls `0x38`. In our glue code, we jump to `aciaInt`.

In `aciaInt`, the first thing we do is to check that we're concerned (the `INT`
line can be triggered by other peripherals and we want to ignore those). To do
so, we poll ACIA's status register and see if its receive buffer is full.

If yes, then we fetch that char from ACIA, put it in the buffer and return from
interrupt. That's how the buffer gets full.

## Conclusion

This walkthrough covers only one simple case, but I hope that it gives you keys
to understanding the whole of Collapse OS. You should be able to start from any
other recipe's glue code and walk through it in a way that is similar to what
we've made here.
