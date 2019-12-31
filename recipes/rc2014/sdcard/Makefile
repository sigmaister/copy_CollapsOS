TARGETS = os.bin cfsin/helo
BASEDIR = ../../..
ZASM = $(BASEDIR)/emul/zasm/zasm
KERNEL = $(BASEDIR)/kernel
APPS = $(BASEDIR)/apps
CFSPACK = $(BASEDIR)/tools/cfspack/cfspack

.PHONY: all
all: $(TARGETS) sdcard.cfs
os.bin: glue.asm 
cfsin/helo: helo.asm
$(TARGETS):
	$(ZASM) $(KERNEL) $(APPS) < glue.asm > $@

$(CFSPACK):
	make -C $(BASEDIR)/tools/cfspack

sdcard.cfs: cfsin $(CFSPACK)
	$(CFSPACK) cfsin > $@
