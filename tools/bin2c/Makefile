.PHONY: all clean

all: bin2c

bin2c: bin2c.o
	$(CC) -o $@ $<

%.o: %.c
	$(CC) -c -o $@ $<

clean:
	rm -rf bin2c bin2c.o
