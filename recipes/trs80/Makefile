TARGET = os.bin
BASEDIR = ../..
ZASM = $(BASEDIR)/emul/zasm/zasm
KERNEL = $(BASEDIR)/kernel
APPS = $(BASEDIR)/apps

.PHONY: all
all: $(TARGET)
$(TARGET): glue.asm
	$(ZASM) $(KERNEL) $(APPS) < glue.asm > $@
