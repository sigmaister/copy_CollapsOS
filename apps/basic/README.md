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

### Commands

There are two types of commands: normal and direct-only. The latter can only
be invoked in direct mode, not through a code listing.

**bye**. Direct-only. Quits BASIC

**list**. Direct-only. Prints all lines in the code listing, prefixing them
with their associated line number.

**run**. Direct-only. Runs code from the listing, starting with the first one.
If `goto` was previously called in direct mode, we start from that line instead.

**print**. Prints the result of the specified expression, then CR/LF. Can be
given multiple arguments. In that case, all arguments are printed separately
with a space in between. For example, `print 12 13` prints `12 13<cr><lf>`

Unlike anywhere else, the `print` command can take a string inside a double
quote. That string will be printed as-is. For example, `print "foo" 40+2` will
print `foo 42`.

**goto**. Make the next line to be executed the line number specified as an
argument. Errors out if line doesn't exist. Argument can be an expression. If
invoked in direct mode, `run` must be called to actually run the line (followed
by the next, and so on).

**if**. If specified condition is true, execute the rest of the line. Otherwise,
do nothing. For example, `if 2>1 print 12` prints `12` and `if 2<1 print 12`
does nothing. The argument for this command is a "thruth expression".

**input**. Prompts the user for a numerical value and puts that value in the
specified variable. The prompted value is evaluated as an expression and then
stored where specified. For example, `input x` stores the result of the
evaluation in variable `x`. Before the variable name, a quoted string literal
can be specified. In that case, that string will be printed as-is just before
the prompt.

**peek/deek**: Put the value at specified memory address into specified
variable. peek is for a single byte, deek is for a word (little endian). For
example, `peek 42 a` puts the byte value contained in memory address 0x002a
into variable `a`. `deek 42 a` does the same as peek, but also puts the value
of 0x002b into `a`'s MSB.

**poke/doke**: Put the value of specified expression into specified memory
address. For example, `poke 42 0x102+0x40` puts `0x42` in memory address
0x2a (MSB is ignored) and `doke 42 0x102+0x40` does the same as poke, but also
puts `0x01` in memory address 0x2b.

**in**: Same thing as `peek`, but for a I/O port. `in 42 a` generates an input
I/O on port 42 and stores the byte result in `a`.

**out**: Same thing as `poke`, but for a I/O port. `out 42 1+2` generates an
output I/O on port 42 with value 3.

**sleep**: Sleep a number of "units" specified by the supplied expression. A
"unit" depends on the CPU clock speed. At 4MHz, it is roughly 8 microseconds.
