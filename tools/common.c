#include <stdlib.h>
#include <unistd.h>

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

// Send a cmd and also read the "> " prompt
void sendcmdp(int fd, char *cmd)
{
    char junk[2];
    sendcmd(fd, cmd);
    read(fd, &junk, 2);
}
