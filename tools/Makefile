CFLAGS ?= -Wall

MEMDUMP_TGT = memdumpb
MEMDUMP_SRC = memdump.c

all: ${MEMDUMP_TGT}

${MEMDUMP_TGT}: ${MEMDUMP_SRC}
	${CC} ${CFLAGS} ${MEMDUMP_SRC} -o ${MEMDUMP_TGT}

.PHONY: clean
clean:
	rm -f ${MEMDUMP_TGT}
