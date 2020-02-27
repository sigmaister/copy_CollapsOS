PROGNAME = ps2ctl
AVRDUDEMCU ?= t45
AVRDUDEARGS ?= -c usbtiny -P usb 
TARGETS = $(PROGNAME).bin os.sms
BASEDIR = ../../..
ZASM = $(BASEDIR)/emul/zasm/zasm
KERNEL = $(BASEDIR)/kernel
APPS = $(BASEDIR)/apps
AVRA = $(BASEDIR)/emul/zasm/avra
AVRINC = $(BASEDIR)/avr

# Rules

.PHONY: send all clean

all: $(TARGETS)
	@echo Done!

send: $(PROGNAME).bin
	avrdude $(AVRDUDEARGS) -p $(AVRDUDEMCU) -U flash:w:$(PROGNAME).bin

$(PROGNAME).bin: $(PROGNAME).asm
	$(AVRA) $(AVRINC) < $(PROGNAME).asm > $@

os.sms: glue.asm
	$(ZASM) $(KERNEL) $(APPS) < glue.asm > $@

clean:
	rm -f $(TARGETS)
