SHELLAPPS = zasm
APPTARGETS = ${SHELLAPPS:%=cfsin/%} 
CFSTARGETS = $(APPTARGETS) cfsin/user.h
TARGET = os.bin
BASEDIR = ../..
ZASM = $(BASEDIR)/emul/zasm/zasm
KERNEL = $(BASEDIR)/kernel
APPS = $(BASEDIR)/apps
CFSPACK = $(BASEDIR)/tools/cfspack/cfspack

.PHONY: all
all: $(TARGET) floppy.cfs
$(TARGET): glue.asm
	$(ZASM) $(KERNEL) $(APPS) < glue.asm > $@

$(CFSPACK):
	make -C $(BASEDIR)/tools/cfspack

floppy.cfs: $(CFSTARGETS) $(CFSPACK)
	$(CFSPACK) cfsin > $@

$(APPTARGETS):
	$(ZASM) $(KERNEL) $(APPS) user.h < $(APPS)/${@:cfsin/%=%}/glue.asm > $@

cfsin/user.h: user.h
	cp user.h $@

.PHONY: clean
clean:
	rm -f $(CFSTARGETS) floppy.cfs $(TARGET)
