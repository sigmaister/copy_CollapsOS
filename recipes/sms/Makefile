TARGET = os.sms
ZASM = ../../tools/zasm.sh
KERNEL = ../../kernel
APPS = ../../apps

.PHONY: all
all: $(TARGET)
$(TARGET): glue.asm
	$(ZASM) $(KERNEL) $(APPS) < $< > $@
