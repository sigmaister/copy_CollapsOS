#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <libgen.h>

/* This script converts "space-dot" fonts to binary "glyph rows". One byte for
 * each row. In a 5x7 font, each glyph thus use 7 bytes.
 * Resulting bytes are aligned to the **left** of the byte. Therefore, for
 * a 5-bit wide char, ". . ." translates to 0b10101000
 * Left-aligned bytes are easier to work with when compositing glyphs.
 */

int main(int argc, char **argv)
{
    if (argc != 2) {
        fprintf(stderr, "Usage: ./fontcompile fpath\n");
        return 1;
    }
    char *fn = basename(argv[1]);
    if (!fn) {
        return 1;
    }
    int w = 0;
    if ((fn[0] >= '3') && (fn[0] <= '8')) {
        w = fn[0] - '0';
    }
    int h = 0;
    if ((fn[2] >= '3') && (fn[2] <= '8')) {
        h = fn[2] - '0';
    }
    if (!w || !h || fn[1] != 'x') {
        fprintf(stderr, "Not a font filename: (3-8)x(3-8).txt.\n");
        return 1;
    }
    fprintf(stderr, "Reading a %d x %d font\n", w, h);
    FILE *fp = fopen(argv[1], "r");
    if (!fp) {
        fprintf(stderr, "Can't open %s.\n", argv[1]);
        return 1;
    }
    // We start the binary data with our first char, space, which is not in our
    // input but needs to be in our output.
    for (int i=0; i<h; i++) {
        putchar(0);
    }
    int lineno = 1;
    char buf[0x10];
    while (fgets(buf, 0x10, fp)) {
        size_t l = strlen(buf);
        if (l > w+1) { // +1 because of the newline char.
            fprintf(stderr, "Line %d too long.\n", lineno);
            fclose(fp);
            return 1;
        }
        // line can be narrower than width. It's padded with spaces.
        while (l < w+1) {
            buf[l] = ' ';
            l++;
        }
        unsigned char c = 0;
        for (int i=0; i<w; i++) {
            if (buf[i] == '.') {
                c |= (1 << (7-i));
            }
        }
        putchar(c);
        lineno++;
    }
    fclose(fp);
    return 0;
}
