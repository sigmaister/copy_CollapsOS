# basic

**Work in progress, not finished.**

This is a BASIC interpreter which is being written from scratch for Collapse OS.
There are many existing z80 implementations around, some of them open source
and most of them good and efficient, but because a lot of that code overlaps
with code that has already been written for zasm, I believe that it's better to
reuse those bits of code.

Integrating an existing BASIC to Collapse OS seemed a bigger challenge than
writing from scratch, so here I am, writing from scratch again...

The biggest challenge here is to extract code from zasm, adapt it to fit BASIC,
not break anything, and have the wisdom to see when copy/pasting is a better
idea.

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
