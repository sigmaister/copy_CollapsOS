## Code conventions

The code in this project follow certain project-wide conventions, which are
described here. Kernel code and userspace code follow additional conventions
which are described in `kernel/README.md` and `apps/README.md`.

## Defines

Each unit can have its own constants, but some constant are made to be defined
externally. We already have some of those external definitions in platform
includes, but we can have more defines than this.

Many units have a "DEFINES" section listing the constant it expects to be
defined. Make sure that you have these constants defined before you include the
file.

## Variable management

Each unit can define variables. These variables are defined as addresses in
RAM. We know where RAM start from the `RAMSTART` constant in platform includes,
but because those parts are made to be glued together in no pre-defined order,
we need a system to align variables from different modules in RAM.

This is why each unit that has variable expect a `<PREFIX>_RAMSTART`
constant to be defined and, in turn, defines a `<PREFIX>_RAMEND` constant to
carry to the following unit.

Thus, code that glue parts together could look like:

    MOD1_RAMSTART .equ RAMSTART
    #include "mod1.asm"
    MOD2_RAMSTART .equ MOD1_RAMEND
    #include "mod2.asm"

## Register protection

As a general rule, all routines systematically protect registers they use,
including input parameters. This allows us to stop worrying, each time we call
a routine, whether our registers are all messed up.

Some routines stray from that rule, but the fact that they destroy a particular
register is documented. An undocumented register change is considered a bug.
Clean up after yourself, you nasty routine!

Another exception to this rule are "top-level" routines, that is, routines that
aren't designed to be called from other parts of Collapse OS. Those are
generally routines close to an application's main loop.

It is important to note, however, that shadow registers aren't preserved.
Therefore, shadow registers should only be used in code that doesn't call
routines or that call a routine that explicitly states that it preserves
shadow registers.

## Z for success

The vast majority of routines use the Z flag to indicate success. When Z is set,
it indicates success. When Z is unset, it indicates error. This follows the
tradition of a zero indicating success and a nonzero indicating error.

Important note: only Z indicate success. Many routines return a meaningful
nonzero value in A and still set Z to indicate success.

In error conditions, however, most of the time A is set to an error code.

In many routines, this is specified verbosely, but it's repeated so often that
I started writing it in short form, "Z for success", which means what is
described here.

## Stack management

Keeping the stack "balanced" is a big challenge when writing assembler code.
Those push and pop need to correspond, otherwise we end up with completely
broken code.

The usual "push/pop" at the beginning and end of a routine is rather easy to
manage, nothing special about them.

The problem is for the "inner" push and pop, which are often necessary in
routines handling more data at once. In those cases, we walk on eggshells.

A naive approach could be to indent the code between those push/pop, but indent
level would quickly become too big to fit in 80 chars.

I've tried ASCII art in some places, where comments next to push/pop have "|"
indicating the scope of the push/pop. It's nice, but it makes code complicated
to edit, especially when dense comments are involved. The pipes have to go
through them.

Of course, one could add descriptions next to each push/pop describing what is
being pushed, and I do it in some places, but it doesn't help much in easily
tracking down stack levels.

So, what I've started doing is to accompany each "non-routine" (at the
beginning and end of a routine) push/pop with "--> lvl X" and "<-- lvl X"
comments. Example:

    push    af  ; --> lvl 1
    inc     a
    push    af  ; --> lvl 2
    inc     a
    pop     af  ; <-- lvl 2
    pop     af  ; <-- lvl 1

I think that this should do the trick, so I'll do this consistently from now on.
[zasm]: ../apps/zasm/README.md
