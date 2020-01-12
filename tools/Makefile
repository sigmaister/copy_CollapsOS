MEMDUMP_TGT = memdump
BLKDUMP_TGT = blkdump
UPLOAD_TGT = upload
FONTCOMPILE_TGT = fontcompile
TTYSAFE_TGT = ttysafe
PINGPONG_TGT = pingpong
TARGETS = $(MEMDUMP_TGT) $(BLKDUMP_TGT) $(UPLOAD_TGT) $(FONTCOMPILE_TGT) \
	$(TTYSAFE_TGT) $(PINGPONG_TGT)
OBJS = common.o

all: $(TARGETS)

.SUFFIXES: .c .o
.c.o:
	$(CC) $(CFLAGS) -c $< -o $@

$(TARGETS): $@.c $(OBJS)
	$(CC) $(CFLAGS) $@.c $(OBJS) -o $@

.PHONY: clean
clean:
	rm -f $(TARGETS) $(OBJS)
