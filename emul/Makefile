TARGETS = runbin/runbin forth/forth
# Those Forth source files are in a particular order
FORTHSRCS = core.fs str.fs parse.fs readln.fs fmt.fs z80a.fs
FORTHSRC_PATHS = ${FORTHSRCS:%=../forth/%} forth/run.fs
OBJS = emul.o libz80/libz80.o
SLATEST = ../tools/slatest

.PHONY: all
all: $(TARGETS)

$(SLATEST):
	$(MAKE) -C ../tools

# z80c.bin and boot.bin are not in the prerequisites because they're bootstrap
# binaries that should be updated manually through make updatebootstrap.
forth/forth0.bin: $(SLATEST)
	cat forth/boot.bin forth/z80c.bin > $@
	$(SLATEST) $@
	cat forth/emul.fs >> $@

forth/forth0-bin.h: forth/forth0.bin
	./bin2c.sh KERNEL < forth/forth0.bin | tee $@ > /dev/null

forth/stage1: forth/stage.c $(OBJS) forth/forth0-bin.h 
	$(CC) forth/stage.c $(OBJS) -o $@

forth/stage1dbg: forth/stage.c $(OBJS) forth/forth0-bin.h 
	$(CC) -DDEBUG forth/stage.c $(OBJS) -o $@

forth/core.bin: $(FORTHSRC_PATHS) forth/stage1
	cat $(FORTHSRC_PATHS) ./forth/stop.fs | ./forth/stage1 | tee $@ > /dev/null

forth/forth1.bin: forth/core.bin $(SLATEST)
	cat forth/boot.bin forth/z80c.bin forth/core.bin > $@
	$(SLATEST) $@

forth/forth1-bin.h: forth/forth1.bin
	./bin2c.sh KERNEL < forth/forth1.bin | tee $@ > /dev/null

forth/stage2: forth/stage.c $(OBJS) forth/forth1-bin.h 
	$(CC) -DSTAGE2 forth/stage.c $(OBJS) -o $@

forth/forth: forth/forth.c $(OBJS) forth/forth1-bin.h 
	$(CC) forth/forth.c $(OBJS) -o $@

runbin/runbin: runbin/runbin.c $(OBJS)
	$(CC) runbin/runbin.c $(OBJS) -o $@

libz80/libz80.o: libz80/z80.c
	$(MAKE) -C libz80/codegen opcodes
	$(CC) -Wall -ansi -g -c -o libz80/libz80.o libz80/z80.c

emul.o: emul.c
	$(CC) -c -o emul.o emul.c


.PHONY: updatebootstrap
updatebootstrap: forth/stage2
	cat ./forth/conf.fs ../forth/boot.fs | ./forth/stage2 | tee forth/boot.bin > /dev/null
	cat ./forth/conf.fs ../forth/z80c.fs ../forth/icore.fs | ./forth/stage2 | tee forth/z80c.bin > /dev/null

.PHONY: clean
clean:
	rm -f $(TARGETS) emul.o forth/*-bin.h forth/forth?.bin
