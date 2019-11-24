# BASIC as a shell

This recipe demonstrate the replacement of the usual shell with the BASIC
interpreter supplied in Collapse OS. To make things fun, we play with I/Os
using RC2014's Digital I/O module.

## Gathering parts

* Same parts as in the base recipe
* (Optional) RC2014's Digital I/O module

The Digital I/O module is only used in the example BASIC code. If you don't
have the module, just use BASIC in another fashion.

## Build the image

As usual, building `os.bin` is a matter of running `make`. Then, you can get
that image to your EEPROM like you did in the base recipe.

## Usage

Upon boot, you'll directy be in a BASIC prompt. See documentation in
`apps/basic/README.md` for details.

For now, let's have some fun with the Digital I/O module. Type this:

```
> a=0
> 10 out 0 a
> 20 sleep 0xffff
> 30 a=a+1
> 40 goto 10
> run
```

You now have your Digital I/O lights doing a pretty dance, forever.

## Looking at the glue code

If you look at the glue code, you'll see that it's very similar to the one in
the base recipe, except that the shell includes have been replaced by the basic
includes. Those includes have been copy/pasted from `apps/basic/glue.asm` and
`USER_RAMSTART` has been replaced with `STDIO_RAMEND` so that BASIC's memory
gets placed properly (that is, right after the kernel's memory).

Simple, isn't it?
