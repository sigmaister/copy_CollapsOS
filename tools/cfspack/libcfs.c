#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <dirent.h>
#include <string.h>
#include <fnmatch.h>
#include <libgen.h>
#include <sys/stat.h>

#include "cfs.h"

#define PUTC(c) putc(c, spitstream)

static FILE *spitstream = stdout;

void set_spit_stream(FILE *stream)
{
    spitstream = stream;
}

int is_regular_file(char *path)
{
    struct stat path_stat;
    stat(path, &path_stat);
    return S_ISREG(path_stat.st_mode);
}

void spitempty()
{
    PUTC('C');
    PUTC('F');
    PUTC('S');
    for (int i=0; i<0x20-3; i++) {
        PUTC(0);
    }
}

int spitblock(char *fullpath, char *fn)
{
    FILE *fp = fopen(fullpath, "r");
    fseek(fp, 0, SEEK_END);
    long fsize = ftell(fp);
    if (fsize > MAX_FILE_SIZE) {
        fclose(fp);
        fprintf(stderr, "File too big: %s %ld\n", fullpath, fsize);
        return 1;
    }
    /* Compute block count.
     * We always have at least one, which contains 0x100 bytes - 0x20, which is
     * metadata. The rest of the blocks have a steady 0x100.
     */
    unsigned char blockcount = 1;
    int fsize2 = fsize - (BLKSIZE - HEADERSIZE);
    if (fsize2 > 0) {
        blockcount += (fsize2 / BLKSIZE);
    }
    if (blockcount * BLKSIZE < fsize + HEADERSIZE) {
        blockcount++;
    }
    PUTC('C');
    PUTC('F');
    PUTC('S');
    PUTC(blockcount);
    // file size is little endian
    PUTC(fsize & 0xff);
    PUTC((fsize >> 8) & 0xff);
    int fnlen = strlen(fn);
    for (int i=0; i<MAX_FN_LEN; i++) {
        if (i < fnlen) {
            PUTC(fn[i]);
        } else {
            PUTC(0);
        }
    }
    // And the last FN char which is always null
    PUTC(0);
    char buf[MAX_FILE_SIZE] = {0};
    rewind(fp);
    fread(buf, fsize, 1, fp);
    fclose(fp);
    fwrite(buf, (blockcount * BLKSIZE) - HEADERSIZE, 1, spitstream);
    fflush(spitstream);
    return 0;
}

int spitdir(char *path, char *prefix, char **patterns)
{
    DIR *dp;
    struct dirent *ep;

    int prefixlen = strlen(prefix);
    dp = opendir(path);
    if (dp == NULL) {
        fprintf(stderr, "Couldn't open directory.\n");
        return 1;
    }
    while ((ep = readdir(dp))) {
        if ((strcmp(ep->d_name, ".") == 0) || strcmp(ep->d_name, "..") == 0) {
            continue;
        }
        if (ep->d_type != DT_DIR && ep->d_type != DT_REG) {
            fprintf(stderr, "Only regular file or directories are supported\n");
            return 1;
        }
        int slen = strlen(ep->d_name);
        if (prefixlen + slen> MAX_FN_LEN) {
            fprintf(stderr, "Filename too long: %s/%s\n", prefix, ep->d_name);
            return 1;
        }
        char fullpath[0x1000];
        strcpy(fullpath, path);
        strcat(fullpath, "/");
        strcat(fullpath, ep->d_name);
        char newprefix[MAX_FN_LEN];
        strcpy(newprefix, prefix);
        if (prefixlen > 0) {
            strcat(newprefix, "/");
        }
        strcat(newprefix, ep->d_name);
        if (ep->d_type == DT_DIR) {
            int r = spitdir(fullpath, newprefix, patterns);
            if (r != 0) {
                return r;
            }
        } else {
            char **p = patterns;
            // if we have no pattern, we match all
            if (p && *p) {
                int matches = 0;
                while (*p) {
                    if (fnmatch(*p, ep->d_name, 0) == 0) {
                        matches = 1;
                        break;
                    }
                    p++;
                }
                if (!matches) {
                    continue;
                }
            }

            int r = spitblock(fullpath, newprefix);
            if (r != 0) {
                return r;
            }
        }
    }
    closedir(dp);
    return 0;
}
