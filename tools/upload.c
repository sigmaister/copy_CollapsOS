#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>

#include "common.h"

/* Push specified file to specified device **running the BASIC shell** and verify
 * that the sent contents is correct.
 */

int main(int argc, char **argv)
{
    if (argc != 4) {
        fprintf(stderr, "Usage: ./upload device memptr fname\n");
        return 1;
    }
    unsigned int memptr = strtol(argv[2], NULL, 16);
    FILE *fp = fopen(argv[3], "r");
    if (!fp) {
        fprintf(stderr, "Can't open %s.\n", argv[3]);
        return 1;
    }
    fseek(fp, 0, SEEK_END);
    unsigned int bytecount = ftell(fp);
    fprintf(stderr, "memptr: 0x%04x bytecount: 0x%04x.\n", memptr, bytecount);
    if (memptr+bytecount > 0xffff) {
        fprintf(stderr, "memptr+bytecount out of range.\n");
        fclose(fp);
        return 1;
    }
    rewind(fp);
    int fd = open(argv[1], O_RDWR|O_NOCTTY);
    char s[0x10];
    sprintf(s, "m=0x%04x", memptr);
    sendcmd(fd, s);
    read(fd, s, 2); // read prompt

    while (fread(s, 1, 1, fp)) {
        putchar('.');
        fflush(stdout);
        unsigned char c = s[0];
        sendcmd(fd, "getc");
        write(fd, &c, 1);
        read(fd, s, 2); // read prompt
        sendcmd(fd, "puth a");
        read(fd, s, 2); // read hex pair
        s[2] = 0; // null terminate
        unsigned char c2 = strtol(s, NULL, 16);
        read(fd, s, 2); // read prompt
        if (c != c2) {
            // mismatch!
            unsigned int pos = ftell(fp);
            fprintf(stderr, "Mismatch at byte %d! %d != %d.\n", pos, c, c2);
            return 1;
        }
        sendcmd(fd, "poke m a");
        read(fd, s, 2); // read prompt
        sendcmd(fd, "m=m+1");
        read(fd, s, 2); // read prompt
    }
    printf("Done!\n");
    return 0;
}

