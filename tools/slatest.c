#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>

/* Update the "LATEST" offset of target Forth binary according to filesize. */

#define OFFSET 0x08

int main(int argc, char **argv)
{
    if (argc != 2) {
        fprintf(stderr, "Usage: ./slatest fname\n");
        return 1;
    }
    FILE *fp = fopen(argv[1], "r+");
    if (!fp) {
        fprintf(stderr, "Can't open %s.\n", argv[1]);
        return 1;
    }
    fseek(fp, 0, SEEK_END);
    unsigned int bytecount = ftell(fp);
    fseek(fp, OFFSET, SEEK_SET);
    char buf[2];
    buf[0] = bytecount & 0xff;
    buf[1] = bytecount >> 8;
    fwrite(buf, 2, 1, fp);
    fclose(fp);
}
