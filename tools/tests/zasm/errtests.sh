#!/bin/sh

# no "set -e" because we test errors

ZASM=../../zasm.sh

chkerr() {
    echo "Check that '$1' results in error $2"
    ${ZASM} > /dev/null <<XXX
$1
XXX
    local res=$?
    if [ $res = $2 ]; then
        echo "Good!"
    else
        echo "$res != $2"
        exit 1
    fi
}

chkoom() {
    echo "Trying OOM error..."
    local tmp=$(mktemp)
    # 300 x 27-29 bytes > 8192 bytes. Large enough to smash the pool.
    local i=0
    while [ "$i" -lt "300" ]; do
        echo ".equ abcdefghijklmnopqrstuvwxyz$i 42" >> ${tmp}
        i=$(($i+1))
    done
    ${ZASM} < ${tmp} > /dev/null
    local res=$?
    rm ${tmp}
    if [ $res = 23 ]; then
        echo "Good!"
    else
        echo "$res != 23"
        exit 1
    fi
}

chkerr "foo" 17
chkerr "ld a, foo" 18
chkerr "ld a, hl" 18
chkerr ".db foo" 18
chkerr ".dw foo" 18
chkerr ".equ foo bar" 18
chkerr ".org foo" 18
chkerr ".fill foo" 18
chkerr "ld a," 19
chkerr "ld a, 'A" 19
chkerr ".db 0x42," 19
chkerr ".dw 0x4242," 19
chkerr ".equ" 19
chkerr ".equ foo" 19
chkerr ".org" 19
chkerr ".fill" 19
chkerr ".inc" 19
chkerr ".inc foo" 19
chkerr "ld a, 0x100" 20
chkerr ".db 0x100" 20
# TODO: find out why this tests fails on Travis but not on my machine...
# chkerr $'nop \ nop \ nop\n.fill 2-$' 20
chkerr ".inc \"doesnotexist\"" 21
chkerr 'foo:\\foo:' 22
chkoom
