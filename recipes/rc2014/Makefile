TARGET = os.bin
BASEDIR = ../..
FDIR = $(BASEDIR)/emul/forth
STAGE1 = $(FDIR)/stage1
FORTH0 = $(FDIR)/forth0.bin
EMUL = $(BASEDIR)/emul/hw/rc2014/classic
SRCS = core.fs str.fs parse.fs readln.fs fmt.fs
PATHS = conf.fs \
	${SRCS:%=$(BASEDIR)/forth/%} \
	$(BASEDIR)/drv/acia.fs \
	run.fs \
	$(FDIR)/stop.fs
SLATEST = $(BASEDIR)/tools/slatest

.PHONY: all
all: $(TARGET) 
$(TARGET): dict.bin $(FORTH0) $(SLATEST)
	cat $(FORTH0) dict.bin > $@
	$(SLATEST) $@

dict.bin: conf.fs
	cat $(PATHS) | $(STAGE1) > $@

$(SLATEST):
	$(MAKE) -C $(BASEDIR)/tools

$(EMUL):
	$(MAKE) -C ${@:%/classic=%}

.PHONY: emul
emul: $(EMUL) $(TARGET)
	$(EMUL) $(TARGET)
	
