#!/bin/sh -e

AVRA=../../emul/zasm/avra

cmpas() {
    FN=$1
    EXPECTED=$(xxd ${FN%.*}.expected)
    ACTUAL=$(cat ${FN} | $AVRA | xxd)
    if [ "$ACTUAL" = "$EXPECTED" ]; then
        echo ok
    else
        echo actual
        echo "$ACTUAL"
        echo expected
        echo "$EXPECTED"
        exit 1
    fi
}

if [ ! -z $1 ]; then
    cmpas $1
    exit 0
fi

for fn in *.asm; do
    echo "Comparing ${fn}"
    cmpas $fn
done
