CFSPACK_OBJ = ../tools/cfspack/libcfs.o
TARGETS = shell/shell zasm/zasm runbin/runbin forth/forth
KERNEL = ../kernel
APPS = ../apps
ZASMBIN = zasm/zasm
AVRABIN = zasm/avra
SHELLAPPS = zasm ed
SHELLTGTS = ${SHELLAPPS:%=cfsin/%}
BIN2C = ../tools/bin2c/bin2c
# Those Forth source files are in a particular order
FORTHSRCS = core.fs str.fs parse.fs readln.fs fmt.fs z80a.fs
FORTHSRC_PATHS = ${FORTHSRCS:%=../forth/%}
CFSIN_CONTENTS = $(SHELLTGTS) cfsin/user.h
OBJS = emul.o libz80/libz80.o
SHELLOBJS = $(OBJS) $(CFSPACK_OBJ)
ZASMOBJS = $(SHELLOBJS)

.PHONY: all
all: $(TARGETS) $(AVRABIN) $(CFSIN_CONTENTS)

$(BIN2C): ../tools/bin2c/bin2c.c
	$(MAKE) -C ../tools/bin2c

# -o in sync with SHELL_CODE in shell/glue.asm
shell/shell.bin: shell/glue.asm $(ZASMBIN) $(BIN2C)
	$(ZASMBIN) $(KERNEL) shell/user.h $(APPS) < shell/glue.asm | tee $@ > /dev/null

shell/shell-bin.h: shell/shell.bin $(BIN2C)
	$(BIN2C) KERNEL < shell/shell.bin | tee $@ > /dev/null

shell/shell: shell/shell.c $(SHELLOBJS) shell/shell-bin.h 
	$(CC) shell/shell.c $(SHELLOBJS) -o $@

# z80c.bin is not in the prerequisites because its a bootstrap binary that
# should be updated manually through make fbootstrap.
forth/forth0.bin:
	cat forth/boot.bin forth/z80c.bin > $@

forth/forth0-bin.h: forth/forth0.bin $(BIN2C)
	$(BIN2C) KERNEL < forth/forth0.bin | tee $@ > /dev/null

forth/stage1: forth/stage.c $(OBJS) forth/forth0-bin.h 
	$(CC) forth/stage.c $(OBJS) -o $@

forth/stage1dbg: forth/stage.c $(OBJS) forth/forth0-bin.h 
	$(CC) -DDEBUG -DBOOT forth/stage.c $(OBJS) -o $@

forth/core.bin: $(FORTHSRC_PATHS) forth/stage1
	cat $(FORTHSRC_PATHS) ./forth/stop.fs | ./forth/stage1 | tee $@ > /dev/null

forth/forth1.bin: forth/forth0.bin forth/core.bin
	cat forth/forth0.bin forth/core.bin > $@

forth/forth1-bin.h: forth/forth1.bin $(BIN2C)
	$(BIN2C) KERNEL < forth/forth1.bin | tee $@ > /dev/null

forth/stage2: forth/stage.c $(OBJS) forth/forth1-bin.h 
	$(CC) -DSTAGE2 forth/stage.c $(OBJS) -o $@

forth/forth: forth/forth.c $(OBJS) forth/forth1-bin.h 
	$(CC) forth/forth.c $(OBJS) -o $@

zasm/kernel-bin.h: zasm/kernel.bin $(BIN2C)
	$(BIN2C) KERNEL < zasm/kernel.bin | tee $@ > /dev/null

zasm/zasm-bin.h: zasm/zasm.bin $(BIN2C)
	$(BIN2C) USERSPACE < zasm/zasm.bin | tee $@ > /dev/null

$(ZASMBIN): zasm/zasm.c $(ZASMOBJS) zasm/kernel-bin.h zasm/zasm-bin.h
	$(CC) zasm/zasm.c $(ZASMOBJS) -o $@

zasm/avra.bin: $(ZASMBIN)
	$(ZASMBIN) $(KERNEL) $(APPS) zasm/user.h < $(APPS)/zasm/gluea.asm > $@

zasm/avra-bin.h: zasm/avra.bin $(BIN2C)
	$(BIN2C) USERSPACE < zasm/avra.bin | tee $@ > /dev/null

$(AVRABIN): zasm/zasm.c $(ZASMOBJS) zasm/kernel-bin.h zasm/avra-bin.h
	$(CC) -D AVRA zasm/zasm.c $(ZASMOBJS) -o $@

runbin/runbin: runbin/runbin.c $(OBJS)
	$(CC) runbin/runbin.c $(OBJS) -o $@

libz80/libz80.o: libz80/z80.c
	$(MAKE) -C libz80/codegen opcodes
	$(CC) -Wall -ansi -g -c -o libz80/libz80.o libz80/z80.c

emul.o: emul.c
	$(CC) -c -o emul.o emul.c

$(CFSPACK_OBJ): ${@:%.o=%.c}
	$(MAKE) -C ../tools/cfspack

# -o in sync with USER_CODE in shell/user.h
$(SHELLTGTS): $(ZASMBIN)
	$(ZASMBIN) -o 42 $(KERNEL) $(APPS) shell/user.h < $(APPS)/${@:cfsin/%=%}/glue.asm > $@

cfsin/user.h: shell/user.h
	cp shell/user.h $@

.PHONY: updatebootstrap
updatebootstrap: $(ZASMBIN)
	$(ZASMBIN) $(KERNEL) < zasm/glue.asm > zasm/kernel.bin
	$(ZASMBIN) $(KERNEL) $(APPS) zasm/user.h < $(APPS)/zasm/glue.asm > zasm/zasm.bin

# We need to double wrap around dummy.fs because at stage3, we have high-level
# words and they write to HERE at initialization.
.PHONY: fbootstrap
fbootstrap: forth/stage2
	cat ./forth/conf.fs ../forth/boot.fs | ./forth/stage2 > forth/boot.bin
	cat ./forth/conf.fs ../forth/z80c.fs forth/emul.fs ../forth/icore.fs | ./forth/stage2 | tee forth/z80c.bin > /dev/null

.PHONY: clean
clean:
	rm -f $(TARGETS) $(SHELLTGTS) emul.o zasm/*-bin.h shell/*-bin.h
	$(MAKE) -C ../tools/bin2c clean
