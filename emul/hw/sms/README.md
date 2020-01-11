# Sega Master System emulator

This emulates a Sega Master system with a monochrome screen and a Genesis pad
hooked to port A.

## Build

You need `xcb` and `pkg-config` to build this. If you have them, run `make`.
You'll get a `sms` executable.

## Usage

Launch the emulator with `./sms /path/to/rom` (you can use the binary from the
`sms` recipe.

This will show a window with the screen's content on it. The mappings to the
pad are:

* Arrows
* Z --> A
* X --> B
* C --> C
* S --> Start

Press ESC to quit.
