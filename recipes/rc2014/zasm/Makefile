SHELLAPPS = zasm sdct memt at28w
APPTARGETS = ${SHELLAPPS:%=cfsin/%} 
CFSTARGETS = $(APPTARGETS) cfsin/user.h
BASE = ../../..
TOOLS = $(BASE)/tools
ZASM = $(TOOLS)/zasm.sh
KERNEL = $(BASE)/kernel
APPS = $(BASE)/apps
CFSPACK = $(TOOLS)/cfspack/cfspack

.PHONY: all
all: os.bin sdcard.cfs

os.bin: glue.asm
	$(ZASM) $(KERNEL) $(APPS) < $< > $@

$(CFSPACK):
	make -C $(TOOLS)/cfspack

sdcard.cfs: $(CFSTARGETS) $(CFSPACK)
	$(CFSPACK) cfsin > $@

$(APPTARGETS): $(ZASMBIN)
	$(ZASM) $(KERNEL) $(APPS) user.h < $(APPS)/${@:cfsin/%=%}/glue.asm > $@

cfsin/user.h: user.h
	cp $< $@

.PHONY: clean
clean:
	rm -f $(CFSTARGETS) sdcard.cfs os.bin
