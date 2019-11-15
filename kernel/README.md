# Kernel

Bits and pieces of code that you can assemble to build a kernel for your
machine.

These parts are made to be glued together in a single `glue.asm` file you write
yourself.

This code is designed to be assembled by Collapse OS' own [zasm][zasm].

## Scope

Units in the `kernel/` folder is about device driver, abstractions over them
as well as the file system. Although a typical kernel boots to a shell, the
code for that shell is not considered part of the kernel code (even if, most of
the time, it's assembled in the same binary). Shells are considered userspace
applications (which live in `apps/`).
