# Testing Collapse OS

This folder contains Collapse OS' automated testing suite. To run, it needs
`tools/emul` to be built. You can run all tests with `make`.

## zasm

This folder tests zasm's assembling capabilities by assembling test source files
and compare the results with expected binaries. These binaries used to be tested
with a golden standard assembler, scas, but at some point compatibility with
scas was broken, so we test against previously generated binaries, making those
tests essentially regression tests.

Those reference binaries sometimes change, especially when we update code in
core libraries because some tests include them. In this case, we have to update
binaries to the new expected value by being extra careful not to introduce a
regression in test references.

## unit

Those tests target specific routines to test and test them using
`tools/emul/runbin` which:

1. Loads the specified binary
2. Runs it until it halts
3. Verifies that `A` is zero. If it's not, we're in error and we display the
   value of `A`.

Test source code has no harnessing and is written in a very "hands on" approach.
At the moment, debugging a test failure is a bit tricky because the error code
often doesn't tell us much.

The convention is to keep a `testNum` counter variable around and call
`nexttest` after each success so that we can easily have an idea of where we
fail.

Then, if you need to debug the cause of a failure, well, you're on your own.
However, there are tricks.

1. Run `unit/runtests.sh <name of file to test>` to target a specific test unit.
2. Insert a `halt` to see the value of `A` at any given moment: it will be your
   reported error code (if 0, runbin will report a success).
