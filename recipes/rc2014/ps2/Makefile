PROGNAME = ps2ctl
AVRDUDEMCU ?= t45
AVRDUDEARGS ?= -c usbtiny -P usb 
TARGETS = $(PROGNAME).hex os.bin
BASEDIR = ../../..
ZASM = $(BASEDIR)/emul/zasm/zasm
KERNEL = $(BASEDIR)/kernel
APPS = $(BASEDIR)/apps

# Rules

.PHONY: send all clean

all: $(TARGETS)
	@echo Done!

send: $(PROGNAME).hex
	avrdude $(AVRDUDEARGS) -p $(AVRDUDEMCU) -U flash:w:$(PROGNAME).hex

$(PROGNAME).hex: $(PROGNAME).asm
	avra -o $@ $(PROGNAME).asm

os.bin: glue.asm
	$(ZASM) $(KERNEL) $(APPS) < glue.asm > $@

clean:
	rm -f $(TARGETS) *.eep.hex *.obj os.bin
