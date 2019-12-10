#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>

/* Read specified number of bytes at specified memory address through a BASIC
 * remote shell and dump it to stdout.
 */

void sendcmd(int fd, char *cmd)
{
    char junk[2];
    while (*cmd) {
        write(fd, cmd, 1);
        read(fd, &junk, 1);
        cmd++;
        // The other side is sometimes much slower than us and if we don't let
        // it breathe, it can choke.
        usleep(1000);
    }
    write(fd, "\n", 1);
    read(fd, &junk, 2); // sends back \r\n
    usleep(1000);
}

int main(int argc, char **argv)
{
    if (argc != 4) {
        fprintf(stderr, "Usage: ./memdump device memptr bytecount\n");
        return 1;
    }
    unsigned int memptr = strtol(argv[2], NULL, 16);
    unsigned int bytecount = strtol(argv[3], NULL, 16);
    fprintf(stderr, "memptr: 0x%04x bytecount: 0x%04x.\n", memptr, bytecount);
    if (memptr+bytecount > 0xffff) {
        fprintf(stderr, "memptr+bytecount out of range.\n");
        return 1;
    }
    if (!bytecount) {
        // nothing to spit
        return 0;
    }

    int fd = open(argv[1], O_RDWR|O_NOCTTY);
    char s[0x20];
    sprintf(s, "m=0x%04x", memptr);
    sendcmd(fd, s);
    read(fd, s, 2); // read prompt

    for (int i=0; i<bytecount; i++) {
        sendcmd(fd, "peek m");
        read(fd, s, 2); // read prompt
        sendcmd(fd, "puth a");
        read(fd, s, 2); // read hex pair
        s[2] = 0; // null terminate
        unsigned char c = strtol(s, NULL, 16);
        putchar(c);
        read(fd, s, 2); // read prompt
        sendcmd(fd, "m=m+1");
        read(fd, s, 2); // read prompt
    }
    return 0;
}
