SHELLAPPS = zasm sdct memt at28w
APPTARGETS = ${SHELLAPPS:%=cfsin/%} 
CFSTARGETS = $(APPTARGETS) cfsin/user.h
BASEDIR = ../../..
ZASM = $(BASEDIR)/emul/zasm/zasm
KERNEL = $(BASEDIR)/kernel
APPS = $(BASEDIR)/apps
CFSPACK = $(BASEDIR)/tools/cfspack/cfspack

.PHONY: all
all: os.bin sdcard.cfs

os.bin: glue.asm
	$(ZASM) $(KERNEL) $(APPS) < glue.asm > $@

$(CFSPACK):
	make -C $(BASEDIR)/tools/cfspack

sdcard.cfs: $(CFSTARGETS) $(CFSPACK)
	$(CFSPACK) cfsin > $@

$(APPTARGETS): $(ZASMBIN)
	$(ZASM) $(KERNEL) $(APPS) user.h < $(APPS)/${@:cfsin/%=%}/glue.asm > $@

cfsin/user.h: user.h
	cp user.h $@

.PHONY: clean
clean:
	rm -f $(CFSTARGETS) sdcard.cfs os.bin
