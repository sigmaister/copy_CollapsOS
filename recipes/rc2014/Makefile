TARGET = os.bin
BASEDIR = ../..
FDIR = $(BASEDIR)/forth
EDIR = $(BASEDIR)/emul/forth
STAGE2 = $(EDIR)/stage2
EMUL = $(BASEDIR)/emul/hw/rc2014/classic
PATHS = pre.fs \
	$(FDIR)/core.fs \
	$(FDIR)/cmp.fs \
	$(FDIR)/str.fs \
	$(FDIR)/parse.fs \
	$(BASEDIR)/drv/acia.fs \
	$(FDIR)/print.fs \
	$(FDIR)/readln.fs \
	$(FDIR)/fmt.fs \
	run.fs
SLATEST = $(BASEDIR)/tools/slatest
STRIPFC = $(BASEDIR)/tools/stripfc

.PHONY: all
all: $(TARGET) 
$(TARGET): boot.bin z80c.bin $(SLATEST) $(PATHS)
	cat boot.bin z80c.bin > $@
	$(SLATEST) $@
	cat $(PATHS) | $(STRIPFC) >> $@

z80c.bin: boot.bin
	cat conf.fs $(FDIR)/z80c.fs $(BASEDIR)/drv/acia.z80 $(FDIR)/icore.fs | $(STAGE2) | tee $@ > /dev/null

boot.bin: conf.fs
	cat conf.fs $(FDIR)/boot.fs | $(STAGE2) | tee $@ > /dev/null

$(SLATEST):
	$(MAKE) -C $(BASEDIR)/tools

$(EMUL):
	$(MAKE) -C ${@:%/classic=%}

.PHONY: emul
emul: $(EMUL) $(TARGET)
	$(EMUL) $(TARGET)
	
