# basic

**Work in progress, not finished.**

This is a BASIC interpreter which is being written from scratch for Collapse OS.
There are many existing z80 implementations around, some of them open source
and most of them good and efficient, but because a lot of that code overlaps
with code that has already been written for zasm, I believe that it's better to
reuse those bits of code.

Integrating an existing BASIC to Collapse OS seemed a bigger challenge than
writing from scratch, so here I am, writing from scratch again...

## Design goal

The reason for including a BASIC dialect in Collapse OS is to supply some form
of system administration swiss knife. zasm, ed and the shell can do
theoretically anything, but some tasks (which are difficult to predict) can
possibly be overly tedious. One can think, for example, about hardware
debugging. Poking and peeking around when not sure what we're looking for can
be a lot more effective with the help of variables, conditions and for-loops in
an interpreter.

Because the goal is not to provide a foundation for complex programs, I'm
planning on intentionally crippling this BASIC dialect for the sake of
simplicity. 

The idea here is that the system administrator would build herself many little
tools in assembler and BASIC would be the interactive glue to those tools.

If you find yourself writing complex programs in Collapse OS BASIC, you're on a
wrong path. Back off, that program should be in assembler.

## Glueing

The `glue.asm` file in this folder represents the minimal basic system. There
are additional modules that can be added that aren't added by default, such
as `fs.asm` because they require kernel options that might not be available.

To include these modules, you'll need to write your own glue file and to hook
extra commands through `BAS_FINDHOOK`. Look for examples in `tools/emul` and
in recipes.

## Usage

Upon launch, a prompt is presented, waiting for a command. There are two types
of command invocation: direct and numbered.

A direct command is executed immediately. Example: `print 42` will print `42`
immediately.

A numbered command is added to BASIC's code listing at the specified line
number. For example, `10 print 42` will set line 10 to the string `print 42`.

Code listing can be printed with `list` and can be ran with `run`. The listing
is kept in order of lines. Line number don't need to be sequential. You can
keep leeway in between your lines and then insert a line with a middle number
later.

Some commands take arguments. Those are given by typing a whitespace after the
command name and then the argument. Additional arguments are given the same way,
by typing a whitespace.

### Numbers, expressions and variables

Numbers are stored in memory as 16-bit integers (little endian) and numbers
being represented by BASIC are expressed as signed integers, in decimal form.
Line numbers, however, are expressed and treated as unsigned integers: You can,
if you want, put something on line "-1", but it will be the equivalent of line
65535. When expressing number literals, you can do so either in multiple forms.
See "Number literals" in `apps/README.md` for details.

Expressions are accepted wherever a number is expected. For example,
`print 2+3` will print `5`.  See "Expressions" in `apps/README.md`.

Inside a `if` command, "truth" expressions are accepted (`=`, `<`, `>`, `<=`,
`>=`). A thruth expression that doesn't contain a truth operator evaluates the
number as-is: zero if false, nonzero is true.

There are 26 one-letter variables in BASIC which can be assigned a 16-bit
integer to them. You assign a value to a variable with `=`. For example,
`a=42+4` will assign 46 to `a` (case insensitive). Those variables can then
be used in expressions. For example, `print a-6` will print `40`. All variables
are initialized to zero on launch.

### Arguments

Some commands take arguments and there are some common patterns regarding them.

One of them is that all commands that "return" something (`input`, `peek`,
etc.) always to so in variable `A`.

Another is that whenever a number is expected, expressions, including the ones
with variables in it, work fine.

### Commands

There are two types of commands: normal and direct-only. The latter can only
be invoked in direct mode, not through a code listing.

**bye**: Direct-only. Quits BASIC

**list**: Direct-only. Prints all lines in the code listing, prefixing them
with their associated line number.

**run**: Direct-only. Runs code from the listing, starting with the first one.
If `goto` was previously called in direct mode, we start from that line instead.

**clear**: Direct-only. Clears the current code listing.

**print <what> [<what>]**: Prints the result of the specified expression,
then CR/LF.  Can be given multiple arguments. In that case, all arguments are
printed separately with a space in between. For example, `print 12 13` prints
`12 13<cr><lf>`

Unlike anywhere else, the `print` command can take a string inside a double
quote. That string will be printed as-is. For example, `print "foo" 40+2` will
print `foo 42`.

**goto <lineno>**: Make the next line to be executed the line number
specified as an argument. Errors out if line doesn't exist. Argument can be
an expression. If invoked in direct mode, `run` must be called to actually
run the line (followed by the next, and so on).

**if <cond> <cmd>**: If specified condition is true, execute the rest of the
line. Otherwise, do nothing. For example, `if 2>1 print 12` prints `12` and `if
2<1 print 12` does nothing. The argument for this command is a "thruth
expression".

**input [<prompt>]**: Prompts the user for a numerical value and puts that
value in `A`. The prompted value is evaluated as an expression and then stored.
The command takes an optional string literal parameter. If present, that string
will be printed before asking for input. Unlike a `print` call, there is no
CR/LF after that print.

**peek/deek <addr>**: Put the value at specified memory address into `A`. peek is for
a single byte, deek is for a word (little endian). For example, `peek 42` puts
the byte value contained in memory address 0x002a into variable `A`. `deek 42`
does the same as peek, but also puts the value of 0x002b into `A`'s MSB.

**poke/doke <addr> <val>**: Put the value of specified expression into
specified memory address. For example, `poke 42 0x102+0x40` puts `0x42` in
memory address 0x2a (MSB is ignored) and `doke 42 0x102+0x40` does the same
as poke, but also puts `0x01` in memory address 0x2b.

**in <port>**: Same thing as `peek`, but for a I/O port. `in 42` generates an
input I/O on port 42 and stores the byte result in `A`.

**out <port> <val>**: Same thing as `poke`, but for a I/O port. `out 42 1+2`
generates an output I/O on port 42 with value 3.

**sleep <units>**: Sleep a number of "units" specified by the supplied
expression. A "unit" depends on the CPU clock speed. At 4MHz, it is roughly 8
microseconds.

**addr <what>**: This very handy returns (in `A`), the address you query for.
You can query for two types of things: commands or special stuff.

If you query for a command, type the name of the command as an argument. The
address of the associated routine will be returned.

Then, there's the *special stuff*. This is the list of things you can query for:

* `$`: the scratchpad.

**usr <addr>**: This calls the memory address specified as an expression
argument.  Before doing so, it sets the registers according to a specific
logic: Variable `A`'s LSB goes in register `A`, variable `D` goes in register
`DE`, `H` in `HL` `B` in `BC` and `X` in `IX`. `IY` can't be used because
it's used for the jump.  Then, after the call, the value of the registers are
put back into the variables following the same logic.

Let's say, for example, that you want to use the kernel's `printstr` to print
the contents of the scratchpad. First, you would call `addr $` to put the
address of the scratchpad in `A`, then do `h=a` to have that address in `HL`
and, if printstr is, for example, the 21st entry in your jump table, you'd do
`usr 21*3` and see the scratchpad printed!

## Optional modules

As explained in "glueing" section abolve, this folder contains optional modules.
Here's the documentation for them.

### blk

Block devices commands. Block devices are configured during kernel
initialization and are referred to by numbers.

**bsel <blkid>**: Select the active block device. The active block device is
the target of all commands below. You select it by specifying its number. For
example, `bsel 0` selects the first configured device. `bsel 1` selects the
second.

A freshly selected blkdev begins with its "pointer" at 0.

**seek <lsw> <msw>**: Moves the blkdev "pointer" to the specified offset. The
first argument is the offset's least significant half (blkdev supports 32-bit
addressing). Is is interpreted as an unsigned integer.

The second argument is optional and is the most significant half of the address.
It defaults to 0.

**getb**: Read a byte in active blkdev at current pointer, then advance the
pointer by one. Read byte goes in `A`.

**putb <val>**: Writes a byte in active blkdev at current pointer, then
advance the pointer by one. The value of the byte is determined by the
expression supplied as an argument. Example: `putb 42`.

### fs

`fs.asm` provides those commands:

**fls**: prints the list of files contained in the active filesystem.

**fopen <fhandle> <fname>**: Open file "fname" in handle "fhandle". File handles
are specified in kernel glue code and are in limited number. The kernel glue
code also maps to blkids through the glue code. So to know what you're doing
here, you have to look at your glue code.

In the emulated code, there are two file handles. Handle 0 maps to blkid 1 and
handle 1 maps to blkid 2.

Once a file is opened, you can use the mapped blkid as you would with any block
device (bseek, getb, putb).

**fnew <blkcnt> <fname>**: Allocates space of "blkcnt" blocks (each block is
0x100 bytes in size) for a new file names "fname". Maximum blkcnt is 0xff.

**fdel <fname>**: Mark file named "fname" as deleted.

**ldbas <fname>**: loads the content of the file specified in the argument
(as an unquoted filename) and replace the current code listing with this
contents. Any line not starting with a number is ignored (not an error).

**basPgmHook**: That is not a command, but a routine to hook into
`BAS_FINDHOOK`. If you do, whenever a command name isn't found, the filesystem
is iterated to see if it finds a file with the same name. If it does, it loads
its contents at `USER_CODE` (from `user.h`) and calls that address, with HL
pointing to the the remaining args in the command line.

The user code called this way follows the *usr* convention for output, that is,
it converts all registers at the end of the call and stores them in appropriate
variables. If `A` is nonzero, an error is considered to have occurred.

It doesn't do var-to-register transfers on input, however. Only HL is passed
through (with the contents of the command line).
