ZASM = ../../../tools/zasm.sh
KERNEL = ../../../kernel
APPS = ../../../apps

.PHONY: all clean
all: os.sms

# -o value synced with offset in glue.asm
ed.bin: $(APPS)/ed/glue.asm
	$(ZASM) -o 19 $(KERNEL) $(APPS) user.h < $< > $@

# -o value synced with offset in glue.asm
zasm.bin: $(APPS)/zasm/glue.asm
	$(ZASM) -o 1d $(KERNEL) $(APPS) user.h < $< > $@

os.sms: glue.asm ed.bin zasm.bin
	$(ZASM) $(KERNEL) $(APPS) ed.bin zasm.bin < $< > $@

clean:
	rm -f os.sms ed.bin zasm.bin
