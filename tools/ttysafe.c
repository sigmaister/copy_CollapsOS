#include <stdlib.h>
#include <stdio.h>

/* Converts stdin to a content that is "tty safe", that is, that it doesn't
 * contain ASCII control characters that can mess up serial communication.
 * How it works is that it leaves any char > 0x20 intact, but any char <= 0x20
 * is replaced by two chars: char|0x80, 0x20. A 0x20 char always indicate "take
 * the char you've just received and unset the 7th bit from it".
 */

int main(void)
{
    int c = getchar();
    while (c != EOF) {
        if (c <= 0x20) {
            putchar(c|0x80);
            putchar(0x20);
        } else {
            putchar(c&0xff);
        }
        c = getchar();
    }
    return 0;
}


