EXTOBJS = ../../emul.o ../../libz80/libz80.o
OBJS = ti84.o t6a04.o kbd.o 
TARGET = ti84
CFLAGS += `pkg-config --cflags xcb`

.PHONY: all
all: $(TARGET)

$(TARGET): $(OBJS) $(EXTOBJS)
	$(CC) `pkg-config --libs xcb` $(OBJS) $(EXTOBJS) -o $@

.PHONY: clean
clean:
	rm -f $(TARGET) $(OBJS)
	
