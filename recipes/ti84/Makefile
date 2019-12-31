TARGET = os.rom
BASEDIR = ../..
ZASM = $(BASEDIR)/emul/zasm/zasm
KERNEL = $(BASEDIR)/kernel
APPS = $(BASEDIR)/apps
MKTIUPGRADE = mktiupgrade

.PHONY: all
all: $(TARGET)
$(TARGET): glue.asm
	$(ZASM) $(KERNEL) $(APPS) < glue.asm > $@
	truncate -s 1M $@

os.8xu: $(TARGET)
	$(MKTIUPGRADE) -p -k keys/0A.key -d TI-84+ $(TARGET) $@ 00

.PHONY: send
send: os.8xu
	tilp -n --calc ti84+ --cable DirectLink os.8xu
