CFSPACK = ../cfspack/cfspack
TARGETS = shell/shell zasm/zasm runbin/runbin
KERNEL = ../../kernel
APPS = ../../apps
ZASMBIN = zasm/zasm
AVRABIN = zasm/avra
ZASMSH = ../zasm.sh
SHELLAPPS = zasm ed
SHELLTGTS = ${SHELLAPPS:%=cfsin/%}
CFSIN_CONTENTS = $(SHELLTGTS) cfsin/user.h
OBJS = emul.o libz80/libz80.o

.PHONY: all
all: $(TARGETS) $(AVRABIN) $(CFSIN_CONTENTS)

# -o in sync with SHELL_CODE in shell/glue.asm
shell/shell.bin: shell/glue.asm $(ZASMBIN)
	$(ZASMSH) $(KERNEL) shell/user.h $(APPS) < shell/glue.asm | tee $@ > /dev/null

shell/shell-bin.h: shell/shell.bin
	./bin2c.sh KERNEL < shell/shell.bin | tee $@ > /dev/null

shell/shell: shell/shell.c $(OBJS) shell/shell-bin.h 
	$(CC) shell/shell.c $(OBJS) -o $@

zasm/kernel-bin.h: zasm/kernel.bin
	./bin2c.sh KERNEL < zasm/kernel.bin | tee $@ > /dev/null

zasm/zasm-bin.h: zasm/zasm.bin
	./bin2c.sh USERSPACE < zasm/zasm.bin | tee $@ > /dev/null

$(ZASMBIN): zasm/zasm.c $(OBJS) zasm/kernel-bin.h zasm/zasm-bin.h $(CFSPACK)
	$(CC) zasm/zasm.c $(OBJS) -o $@

zasm/avra.bin: $(ZASMBIN)
	$(ZASMSH) $(KERNEL) $(APPS) zasm/user.h < $(APPS)/zasm/gluea.asm > $@

zasm/avra-bin.h: zasm/avra.bin
	./bin2c.sh USERSPACE < zasm/avra.bin | tee $@ > /dev/null

$(AVRABIN): zasm/zasm.c $(OBJS) zasm/kernel-bin.h zasm/avra-bin.h
	$(CC) -D AVRA zasm/zasm.c $(OBJS) -o $@

runbin/runbin: runbin/runbin.c $(OBJS)
	$(CC) runbin/runbin.c $(OBJS) -o $@

libz80/libz80.o: libz80/z80.c
	$(MAKE) -C libz80/codegen opcodes
	$(CC) -Wall -ansi -g -c -o libz80/libz80.o libz80/z80.c

emul.o: emul.c
	$(CC) -c -o emul.o emul.c

$(CFSPACK):
	$(MAKE) -C ../cfspack

# -o in sync with USER_CODE in shell/user.h
$(SHELLTGTS): $(ZASMBIN)
	$(ZASMSH) -o 42 $(KERNEL) $(APPS) shell/user.h < $(APPS)/${@:cfsin/%=%}/glue.asm > $@

cfsin/user.h: shell/user.h
	cp shell/user.h $@

.PHONY: updatebootstrap
updatebootstrap: $(ZASMBIN)
	$(ZASMSH) $(KERNEL) < zasm/glue.asm > zasm/kernel.bin
	$(ZASMSH) $(KERNEL) $(APPS) zasm/user.h < $(APPS)/zasm/glue.asm > zasm/zasm.bin

.PHONY: clean
clean:
	rm -f $(TARGETS) $(SHELLTGTS) emul.o zasm/*-bin.h shell/*-bin.h
