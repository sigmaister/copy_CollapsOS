CFSPACK = ../cfspack/cfspack
TARGETS = shell/shell zasm/zasm runbin/runbin
KERNEL = ../../kernel
APPS = ../../apps
ZASMBIN = zasm/zasm
ZASMSH = ../zasm.sh
SHELLAPPS = $(addprefix cfsin/, zasm ed basic)
CFSIN_CONTENTS = $(SHELLAPPS) cfsin/user.h

.PHONY: all
all: $(TARGETS) $(CFSIN_CONTENTS)

# -o in sync with SHELL_CODE in shell/glue.asm
shell/shell.bin: $(APPS)/shell/glue.asm $(ZASMBIN)
	$(ZASMSH) -o 07 $(KERNEL) shell/user.h $(APPS) < $< | tee $@ > /dev/null

shell/kernel-bin.h: shell/glue.asm shell/shell.bin $(ZASMBIN)
	$(ZASMSH) $(KERNEL) shell/shell.bin < $< | ./bin2c.sh KERNEL | tee $@ > /dev/null

zasm/kernel-bin.h: zasm/kernel.bin
	./bin2c.sh KERNEL < $< | tee $@ > /dev/null

zasm/zasm-bin.h: zasm/zasm.bin
	./bin2c.sh USERSPACE < $< | tee $@ > /dev/null

shell/shell: shell/shell.c libz80/libz80.o shell/kernel-bin.h 
$(ZASMBIN): zasm/zasm.c libz80/libz80.o zasm/kernel-bin.h zasm/zasm-bin.h $(CFSPACK)
runbin/runbin: runbin/runbin.c libz80/libz80.o
$(TARGETS):
	$(CC) $< libz80/libz80.o -o $@

libz80/libz80.o: libz80/z80.c
	$(MAKE) -C libz80/codegen opcodes
	$(CC) -Wall -ansi -g -c -o libz80/libz80.o libz80/z80.c

$(CFSPACK):
	$(MAKE) -C ../cfspack

# -o in sync with USER_CODE in shell/user.h
$(SHELLAPPS): $(ZASMBIN)
	$(ZASMSH) -o 42 $(KERNEL) $(APPS) shell/user.h < $(APPS)/$(notdir $@)/glue.asm > $@

cfsin/user.h: shell/user.h
	cp $< $@

.PHONY: updatebootstrap
updatebootstrap: $(ZASMBIN) $(INCCFS)
	$(ZASMSH) $(KERNEL) < zasm/glue.asm > zasm/kernel.bin
	$(ZASMSH) $(KERNEL) $(APPS) zasm/user.h < $(APPS)/zasm/glue.asm > zasm/zasm.bin

.PHONY: clean
clean:
	rm -f $(TARGETS) $(SHELLAPPS) {zasm,shell}/*-bin.h
