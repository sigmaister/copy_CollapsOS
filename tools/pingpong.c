#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>

#include "common.h"

/* Sends the contents of `fname` to `device`, expecting every sent byte to be
 * echoed back verbatim. Compare every echoed byte with the one sent and bail
 * out if a mismatch is detected. When the whole file is sent, push a null char
 * to indicate EOF to the receiving end.
 *
 * It is recommended that you send contents that has gone through `ttysafe`.
 */
int main(int argc, char **argv)
{
    if (argc != 3) {
        fprintf(stderr, "Usage: ./pingpong device fname\n");
        return 1;
    }
    FILE *fp = fopen(argv[2], "r");
    if (!fp) {
        fprintf(stderr, "Can't open %s.\n", argv[2]);
        return 1;
    }
    int fd = open(argv[1], O_RDWR|O_NOCTTY|O_NONBLOCK);
    printf("Press a key...\n");
    getchar();
    unsigned char c;
    // empty the recv buffer
    while (read(fd, &c, 1) == 1) usleep(1000);
    int returncode = 0;
    while (fread(&c, 1, 1, fp)) {
        putchar('.');
        fflush(stdout);
        write(fd, &c, 1);
        usleep(1000); // let it breathe
        unsigned char c2;
        while (read(fd, &c2, 1) != 1); // read echo
        if (c != c2) {
            // mismatch!
            unsigned int pos = ftell(fp);
            fprintf(stderr, "Mismatch at byte %d! %d != %d.\n", pos, c, c2);
            returncode = 1;
            break;
        }
    }
    // To close the receiving loop on the other side, we send a straight null
    c = 0;
    write(fd, &c, 1);
    printf("Done!\n");
    fclose(fp);
    return returncode;
}


