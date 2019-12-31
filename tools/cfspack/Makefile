TARGETS = cfspack cfsunpack

CFSPACK_OBJS = cfspack.o libcfs.o

.PHONY: all
all: $(TARGETS)

cfspack: $(CFSPACK_OBJS)
	$(CC) $(LDFLAGS) -o $@ $(CFSPACK_OBJS)

cfsunpack: cfsunpack.c
	$(CC) $(CFLAGS) -o $@ cfsunpack.c

.PHONY: clean
clean:
	rm -f $(TARGETS)
