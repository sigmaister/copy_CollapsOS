#!/bin/sh -e

EMULDIR=../../emul
SHELL="${EMULDIR}/shell/shell"

replay() {
    fn=$1
    replayfn=${fn%.*}.expected
    ACTUAL=$("${SHELL}" -f test.cfs < "${fn}" 2> /dev/null)
    EXPECTED=$(cat ${replayfn})
    if [ "$ACTUAL" = "$EXPECTED" ]; then
        echo ok
    else
        echo different. Whole output:
        echo "${ACTUAL}"
        exit 1
    fi
}

if [ ! -z $1 ]; then
    replay $1
    exit 0
fi

for fn in *.replay; do
    echo "Replaying ${fn}"
    replay "${fn}"
done
