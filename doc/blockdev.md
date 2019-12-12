# Using block devices

The `blockdev.asm` part manage what we call "block devices", an abstraction over
something that we can read a byte to, write a byte to, optionally at arbitrary
offsets.

A Collapse OS system can define up to `0xff` devices. Those definitions are made
in the glue code, so they are static.

Definition of block devices happen at include time. It would look like:

    [...]
    BLOCKDEV_COUNT .equ 1
    #include "blockdev.asm"
    ; List of devices
    .dw	sdcGetB, sdcPutB
    [...]

That tells `blockdev` that we're going to set up one device, that its GetB and
PutB are the ones defined by `sdc.asm`.

If your block device is read-only or write-only, use dummy routines. `unsetZ`
is a good choice since it will return with the `Z` flag unset, indicating an
error (dummy methods aren't supposed to be called).

Each defined block device, in addition to its routine definition, holds a
seek pointer. This seek pointer is used in shell commands described below.

## Routine definitions

Parts that implement GetB and PutB do so in a loosely-coupled manner, but
they should try to adhere to the convention, that is:

**GetB**: Get the byte at position specified by `HL`. If it supports 32-bit
          addressing, `DE` contains the high-order bytes. Return the result in
          `A`. If there's an error (for example, address out of range), unset
          `Z`. This routine is not expected to block. We expect the result to be
          immediate.

**PutB**: The opposite of GetB. Write the character in `A` at specified
          position. `Z` unset on error.
          
## Shell usage

`apps/basic/blk.asm` supplies 4 shell commands that you can add to your shell.
See "Optional Modules/blk" in [the shell doc](../apps/basic/README.md).

### Example

Let's try an example: You glue yourself a Collapse OS with a mmap starting at
`0xe000` as your 4th device (like it is in the shell emulator). Here's what you
could do to copy memory around:

    > m=0xe000
    > while m<0xe004 getc:poke m a:m=m+1
    [enter "abcd"]
    > bsel 3
    > i=0
    > while i<4 getb:puth a:i=i+1
    61626364> bseek 2
    > getb:puth a
    63> getb:puth a
    64>
