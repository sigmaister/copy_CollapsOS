#include <stdio.h>
#include <stdlib.h>

#define BUFSZ 32

static const char intro[] = "static const unsigned char %s[] = {\n    ";

int main(int argc, char **argv) {
  int n;
  int col = 0;
  uint8_t buf[BUFSZ];
  
  if (argc < 2) {
    fprintf(stderr, "Specify a name for the data structure...\n");
    return 1;
  }

  printf(intro, argv[1]);

  while(!feof(stdin)) {
    n = fread(buf, 1, BUFSZ, stdin);
    for(int i = 0; i < n; ++i) {
      if (col+4 >= 76) {
          printf("\n    ");
          col = 0;
        }
      printf("0x%.2x, ", buf[i]);
      col += 6;
    }
  }

  printf("};\n");
}
