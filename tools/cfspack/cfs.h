#define BLKSIZE 0x100
#define HEADERSIZE 0x20
#define MAX_FN_LEN 25   // 26 - null char
#define MAX_FILE_SIZE (BLKSIZE * 0x100) - HEADERSIZE

void set_spit_stream(FILE *stream);
int is_regular_file(char *path);
void spitempty();
int spitblock(char *fullpath, char *fn);
int spitdir(char *path, char *prefix, char **patterns);
