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
