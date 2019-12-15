# AVR include files

This folder contains header files that can be included in AVR assembly code.

These definitions are organized in a manner that is very similar to other
modern AVR assemblers, but most bits definitions (`PINB4`, `WGM01`, etc.) are
absent. This is because there's a lot of them, each symbol takes memory during
assembly and machines doing the assembling might be tight in memory. AVR code
post collapse will have to take the habit of using numerical masks accompanied
by comments describing associated symbols.

To avoid repeats, those includes are organized in 3 levels. First, there's the
`avr.h` file containing definitions common to all AVR models. Then, there's the
"family" file containing definitions common to a "family" (for example, the
ATtiny 25/45/85). Those definitions are the beefiests. Then, there's the exact
model file, which will typically contain RAM and Flash boundaries.
