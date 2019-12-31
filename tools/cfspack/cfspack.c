#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <dirent.h>
#include <string.h>
#include <fnmatch.h>
#include <libgen.h>
#include <sys/stat.h>

#include "cfs.h"

void usage()
{
    fprintf(stderr, "Usage: cfspack [-p pattern] [/path/to/dir...]\n");
}

int main(int argc, char *argv[])
{
    int patterncount = 0;
    char **patterns = malloc(sizeof(char**));
    patterns[0] = NULL;
    while (1) {
        int c = getopt(argc, argv, "p:");
        if (c < 0) {
            break;
        }
        switch (c) {
            case 'p':
                patterns[patterncount] = optarg;
                patterncount++;
                patterns = realloc(patterns, sizeof(char**)*(patterncount+1));
                patterns[patterncount] = NULL;
                break;
            default:
                usage();
                return 1;
        }
    }
    int res = 0;
    for (int i=optind; i<argc; i++) {
        if (is_regular_file(argv[i])) {
            // special case: just one file
            res = spitblock(argv[i], basename(argv[i]));
        } else {
            res = spitdir(argv[i], "", patterns);
        }
    }
    if (res == 0) {
        spitempty();
    }
    free(patterns);
    return res;
}

