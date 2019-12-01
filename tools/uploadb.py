#!/usr/bin/env python3

# Push specified file to specified device **running the BASIC shell** and verify
# that the sent contents is correct.

import argparse
import os
import sys

def sendcmd(fd, cmd):
    # The serial link echoes back all typed characters and expects us to read
    # them. We have to send each char one at a time.
    if isinstance(cmd, str):
        cmd = cmd.encode()
    for c in cmd:
        os.write(fd, bytes([c]))
        os.read(fd, 1)
    os.write(fd, b'\n')
    os.read(fd, 2)  # sends back \r\n


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('device')
    parser.add_argument('memptr')
    parser.add_argument('filename')
    args = parser.parse_args()

    try:
        memptr = int('0x' + args.memptr, 0)
    except ValueError:
        print("memptr are has to be hexadecimal without prefix.")
        return 1
    if memptr >= 0x10000:
        print("memptr out of range.")
        return 1
    maxsize = 0x10000 - memptr
    st = os.stat(args.filename)
    if st.st_size > maxsize:
        print("File too big. 0x{:04x} bytes max".format(maxsize))
        return 1
    fd = os.open(args.device, os.O_RDWR)
    with open(args.filename, 'rb') as fp:
        fcontents = fp.read()
    sendcmd(fd, f'm=0x{memptr:04x}')
    os.read(fd, 2) # read prompt

    for i, c in enumerate(fcontents):
        c = bytes([c])
        sendcmd(fd, 'getc')
        os.write(fd, c)
        os.read(fd, 2) # read prompt
        sendcmd(fd, 'putc a')
        r = os.read(fd, 1) # putc result
        os.read(fd, 2) # read prompt
        if r != c:
            print(f"Mismatch at byte {i}! {c} != {r}")
        sendcmd(fd, 'poke m a')
        os.read(fd, 2) # read prompt
        sendcmd(fd, 'm=m+1')
        os.read(fd, 2) # read prompt
    print("Done!")
    os.close(fd)
    return 0

if __name__ == '__main__':
    sys.exit(main())
