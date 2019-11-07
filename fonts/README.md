# fonts

This folder contains bitmap fonts that are then converted to ASM data tables.

The format for them is straightforward: dots and spaces. Each line is a line in
the letter (for example, in a 6x8 font, each character is 8 lines of 6
characters each, excluding newline).

They cover the 0x21 to 0x7e range and are placed sequentially in the file.

Dots and spaces allow easy visualisation of the result and is thus rather handy.

Padding is excluded from fonts. For example, 5x7.txt is actually a 6x8 font, but
because characters are always padded, it's useless to keep systematic blank
lines or rows around.
