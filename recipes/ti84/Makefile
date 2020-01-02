TARGET = os.bin
BASEDIR = ../..
ZASM = $(BASEDIR)/emul/zasm/zasm
KERNEL = $(BASEDIR)/kernel
APPS = $(BASEDIR)/apps
MKTIUPGRADE = mktiupgrade

.PHONY: all
all: $(TARGET)
$(TARGET): glue.asm
	$(ZASM) $(KERNEL) $(APPS) < glue.asm > $@

os.rom: $(TARGET)
	cp $(TARGET) $@
	truncate -s 1M $@

os.8xu: os.rom
	$(MKTIUPGRADE) -p -k keys/0A.key -d TI-84+ os.rom $@ 00

.PHONY: send
send: os.8xu
	tilp -n --calc ti84+ --cable DirectLink os.8xu
