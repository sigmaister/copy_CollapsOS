TARGET = os.rom
ZASM = ../../tools/zasm.sh
KERNEL = ../../kernel

.PHONY: all
all: $(TARGET)
$(TARGET): glue.asm
	$(ZASM) $(KERNEL) < $< > $@
	truncate -s 1M $@

