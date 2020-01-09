EXTOBJS = ../../emul.o ../../libz80/libz80.o
OBJS = sms.o vdp.o
TARGET = sms
CFLAGS += `pkg-config --cflags xcb`

.PHONY: all
all: $(TARGET)

$(TARGET): $(OBJS) $(EXTOBJS)
	$(CC) `pkg-config --libs xcb` $(OBJS) $(EXTOBJS) -o $@

.PHONY: clean
clean:
	rm -f $(TARGET) $(OBJS)
	
