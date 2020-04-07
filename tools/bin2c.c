/*
 * Copyright (c) 2020 Byron Grobe
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

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
