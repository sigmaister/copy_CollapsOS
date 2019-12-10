MEMDUMP_TGT = memdumpb
MEMDUMP_SRC = memdump.c
UPLOAD_TGT = uploadb
UPLOAD_SRC = upload.c
TARGETS = $(MEMDUMP_TGT) $(UPLOAD_TGT)
OBJS = common.o

all: $(TARGETS)

.SUFFIXES: .c .o
.c.o:
	$(CC) $(CFLAGS) -c $< -o $@

$(MEMDUMP_TGT): $(MEMDUMP_SRC) $(OBJS)
	$(CC) $(CFLAGS) $(MEMDUMP_SRC) $(OBJS) -o $@

$(UPLOAD_TGT): $(UPLOAD_SRC) $(OBJS)
	$(CC) $(CFLAGS) $(UPLOAD_SRC) $(OBJS) -o $@

.PHONY: clean
clean:
	rm -f $(TARGETS) $(OBJS)
