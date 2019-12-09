TARGETS = cfspack cfsunpack

.PHONY: all
all: $(TARGETS)

cfspack: cfspack.c
	$(CC) $(CFLAGS) -o $@ cfspack.c

cfsunpack: cfsunpack.c
	$(CC) $(CFLAGS) -o $@ cfsunpack.c

.PHONY: clean
clean:
	rm -f $(TARGETS)
