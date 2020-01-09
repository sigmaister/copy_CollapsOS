EXTOBJS = ../../emul.o ../../libz80/libz80.o
OBJS = sms.o vdp.o
TARGET = sms
CFLAGS += `pkg-config --cflags xcb`
LDFLAGS += `pkg-config --libs xcb`

.PHONY: all
all: $(TARGET)

$(TARGET): $(OBJS) $(EXTOBJS)
	$(CC) $(OBJS) $(EXTOBJS) -o $@ $(LDFLAGS)

.PHONY: clean
clean:
	rm -f $(TARGET) $(OBJS)
	
