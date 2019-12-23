# z80 assembler

This is probably the most critical part of the Collapse OS project because it
ensures its self-reproduction.

## Invocation

`zasm` is invoked with 2 mandatory arguments and an optional one. The mandatory
arguments are input blockdev id and output blockdev id. For example, `zasm 0 1`
reads source code from blockdev 0, assembles it and spit the result in blockdev
1.

Input blockdev needs to be seek-able, output blockdev doesn't need to (zasm
writes in one pass, sequentially.

The 3rd argument, optional, is the initial `.org` value. It's the high byte of
the value. For example, `zasm 0 1 4f` assembles source in blockdev 0 as if it
started with the line `.org 0x4f00`. This also means that the initial value of
the `@` symbol is `0x4f00`.

## Running on a "modern" machine

To be able to develop zasm efficiently, [libz80][libz80] is used to run zasm
on a modern machine. The code lives in `emul` and ran be built with `make`,
provided that you have a copy libz80 living in `emul/libz80`.

The resulting `zasm` binary takes asm code in stdin and spits binary in stdout.

## Literals

See "Number literals" in `apps/README.md`.

On top of common literal logic, zasm also has string literals. It's a chain of
characters surrounded by double quotes. Example: `"foo"`. This literal can only
be used in the `.db` directive and is equivalent to each character being
single-quoted and separated by commas (`'f', 'o', 'o'`). No null char is
inserted in the resulting value (unlike what C does).

## Labels

Lines starting with a name followed `:` are labeled. When that happens, the
name of that label is associated with the binary offset of the following
instruction.

For example, a label placed at the beginning of the file is associated with
offset 0. If placed right after a first instruction that is 2 bytes wide, then
the label is going to be bound to 2.

Those labels can then be referenced wherever a constant is expected. They can
also be referenced where a relative reference is expected (`jr` and `djnz`).

Labels can be forward-referenced, that is, you can reference a label that is
defined later in the source file or in an included source file.

Labels starting with a dot (`.`) are local labels: they belong only to the
namespace of the current "global label" (any label that isn't local). Local
namespace is wiped whenever a global label is encountered.

Local labels allows reuse of common mnemonics and make the assembler use less
memory.

Global labels are all evaluated during the first pass, which makes possible to
forward-reference them. Local labels are evaluated during the second pass, but
we can still forward-reference them through a "first-pass-redux" hack.

Labels can be alone on their line, but can also be "inlined", that is, directly
followed by an instruction.

## Constants

The `.equ` directive declares a constant. That constant's argument is an
expression that is evaluated right at parse-time.

Constants are evaluated during the second pass, which means that they can
forward-reference labels.

However, they *cannot* forward-reference other constants.

When defining a constant, if the symbol specified has already been defined, no
error occur and the first value defined stays intact. This allows for "user
override" of programs.

It's also important to note that constants always override labels, regardless
of declaration order.

## Expressions

See "Expressions" in `apps/README.md`.

## The Program Counter

The `$` is a special symbol that can be placed in any expression and evaluated
as the current output offset. That is, it's the value that a label would have if
it was placed there.

## The Last Value

Whenever a `.equ` directive is evaluated, its resulting value is saved in a
special "last value" register that can then be used in any expression. This
last value is referenced with the `@` special symbol. This is very useful for
variable definitions and for jump tables.

Note that `.org` also affect the last value.

## Includes

The `.inc` directive is special. It takes a string literal as an argument and
opens, in the currently active filesystem, the file with the specified name.

It then proceeds to parse that file as if its content had been copy/pasted in
the includer file, that is: global labels are kept and can be referenced
elsewhere. Constants too. An exception is local labels: a local namespace always
ends at the end of an included file.

There an important limitation with includes: only one level of includes is
allowed. An included file cannot have an `.inc` directive.

## Directives

**.db**: Write bytes specified by the directive directly in the resulting
         binary. Each byte is separated by a comma. Example: `.db 0x42, foo`

**.dw**: Same as `.db`, but outputs words. Example: `.dw label1, label2`

**.equ**: Binds a symbol named after the first parameter to the value of the
          expression written as the second parameter. Example:
          `.equ foo 0x42+'A'`. See "Constants" above.
          
**.fill**: Outputs the number of null bytes specified by its argument, an
           expression. Often used with `$` to fill our binary up to a certain
           offset. For example, if we want to place an instruction exactly at
           byte 0x38, we would precede it with `.fill 0x38-$`.

The maximum value possible for `.fill` is `0xd000`. We do this to
avoid "overshoot" errors, that is, error where `$` is greater than
the offset you're trying to reach in an expression like `.fill X-$`
(such an expression overflows to `0xffff`).

**.org**: Sets the Program Counter to the value of the argument, an expression.
          For example, a label being defined right after a `.org 0x400`, would
          have a value of `0x400`. Does not do any filling. You have to do that
          explicitly with `.fill`, if needed. Often used to assemble binaries
          designed to run at offsets other than zero (userland).

**.out**: Outputs the value of the expression supplied as an argument to
          `ZASM_DEBUG_PORT`. The value is always interpreted as a word, so
          there's always two `out` instruction executed per directive. High byte
          is sent before low byte. Useful or debugging, quickly figuring our
          RAM constants, etc. The value is only outputted during the second
          pass.

**.inc**: Takes a string literal as an argument. Open the file name specified
          in the argument in the currently active filesystem, parse that file
          and output its binary content as is the code has been in the includer
          file.

**.bin**: Takes a string literal as an argument. Open the file name specified
          in the argument in the currently active filesystem and outputs its
          contents directly.

## Undocumented instructions

`zasm` doesn't support undocumented instructions such as the ones that involve
using `IX` and `IY` as 8-bit registers. We used to support them, but because
this makes our code incompatible with Z80-compatible CPUs such as the Z180, we
prefer to avoid these in our code.

## AVR assembler

`zasm` can be configured, at compile time, to be a AVR assembler instead of a
z80 assembler. Directives, literals, symbols, they're all the same, it's just
instructions and their arguments that change.

Instructions and their arguments have a ayntax that is similar to other AVR
assemblers: registers are referred to as `rXX`, mnemonics are the same,
arguments are separated by commas.

To assemble an AVR assembler, use the `gluea.asm` file instead of the regular
one.

Note about AVR and PC: In most assemblers, arithmetics for instructions
addresses have words (two bytes) as their basic unit because AVR instructions
are either 16bit in length or 32bit in length. All addresses constants in
upcodes are in words. However, in zasm's core logic, PC is in bytes (because z80
upcodes can be 1 byte).

The AVR assembler, of course, correctly translates byte PCs to words when
writing upcodes, however, when you write your expressions, you need to remember
to treat with bytes. For example, in a traditional AVR assembler, jumping to
the instruction after the "foo" label would be "rjmp foo+1". In zasm, it's
"rjmp foo+2". If your expression results in an odd number, the low bit of your
number will be ignored.

Limitations:

* `CALL` and `JMP` only support 16-bit numbers, not 22-bit ones.
* `BRLO` and `BRSH` are not there. Use `BRCS` and `BRCC` instead.
* No `high()` and `low()`. Use `&0xff` and `}8`.

[libz80]: https://github.com/ggambetta/libz80
