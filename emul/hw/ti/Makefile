OBJS = ti84.o t6a04.o kbd.o ../../emul.o ../../libz80/libz80.o
CFLAGS += `pkg-config --cflags xcb`

ti84: $(OBJS)
	$(CC) `pkg-config --libs xcb` $(OBJS) -o $@

