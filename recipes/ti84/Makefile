TARGET = os.rom
ZASM = ../../tools/zasm.sh
KERNEL = ../../kernel
MKTIUPGRADE = mktiupgrade

.PHONY: all
all: $(TARGET)
$(TARGET): glue.asm
	$(ZASM) $(KERNEL) < $< > $@
	truncate -s 1M $@

os.8xu: $(TARGET)
	$(MKTIUPGRADE) -p -k keys/0A.key -d TI-84+ $< $@ 00

.PHONY: send
send: os.8xu
	tilp -n --calc ti84+ --cable DirectLink $<
