# User applications

This folder contains code designed to be "userspace" application. Unlike the
kernel, which always stay in memory. Those apps here will more likely be loaded
in RAM from storage, ran, then discarded so that another userspace program can
be run.

That doesn't mean that you can't include that code in your kernel though, but
you will typically not want to do that.

## Userspace convention

We execute a userspace application by calling the address it's loaded into.

This means that userspace applications must be assembled with a proper `.org`,
otherwise labels in its code will be wrong.

The `.org`, it is not specified by glue code of the apps themselves. It is
expected to be set either in the `user.h` file to through `zasm` 3rd argument.

That a userspace is called also means that an application, when finished
running, is expected to return with a regular `ret` and a clean stack.

Whatever calls the userspace app (usually, it will be the shell), should set
HL to a pointer to unparsed arguments in string form, null terminated.

The userspace application is expected to set A on return. 0 means success,
non-zero means error.

A userspace application can expect the `SP` pointer to be properly set. If it
moves it, it should take care of returning it where it was before returning
because otherwise, it will break the kernel.

## Memory management

Apps in Collapse OS are design to be ROM-compatible, that is, they don't write
to addresses that are part of the code's address space.

By default, apps set their RAM to begin at the end of the binary because in
most cases, these apps will be ran from RAM. If they're ran from ROM, make sure
to set `USER_RAMSTART` properly in your `user.h` to ensure that the RAM is
placed properly.

Applications that are ran as a shell (the "shell" app, of course, but also,
possibly, "basic" and others to come) need a manual override to their main
`RAMSTART` constant: You don't want them to run in the same RAM region as your
other userspace apps because if you do, as soon as you launch an app with your
shell, its memory is going to be overwritten!

What you'll do then is that you'll reserve some space in your memory layout for
the shell and add a special constant in your `user.h`, which will override the
basic one (remember, in zasm, the first `.equ` for a given constant takes
precedence).

For example, if you want a "basic" shell and that you reserve space right
after your kernel RAM for it, then your `user.h` would contain
`.equ BAS_RAMSTART KERNEL_RAMEND`.

You can also include your shell's code directly in the kernel by copying
relevant parts of the app's glue unit in your kernel's glue unit. This is often
simpler and more efficient. However, if your shell is a big program, it might
run into zasm's limits. In that case, you'd have to assemble your shell
separately.
