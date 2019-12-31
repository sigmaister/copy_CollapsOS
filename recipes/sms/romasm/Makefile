BASEDIR = ../../..
ZASM = $(BASEDIR)/emul/zasm/zasm
KERNEL = $(BASEDIR)/kernel
APPS = $(BASEDIR)/apps

.PHONY: all clean
all: os.sms

# -o value synced with offset in glue.asm
ed.bin: $(APPS)/ed/glue.asm
	$(ZASM) -o 1f $(KERNEL) $(APPS) user.h < $(APPS)/ed/glue.asm > $@

# -o value synced with offset in glue.asm
zasm.bin: $(APPS)/zasm/glue.asm
	$(ZASM) -o 24 $(KERNEL) $(APPS) user.h < $(APPS)/zasm/glue.asm > $@

os.sms: glue.asm ed.bin zasm.bin
	$(ZASM) $(KERNEL) $(APPS) ed.bin zasm.bin < glue.asm > $@

clean:
	rm -f os.sms ed.bin zasm.bin
