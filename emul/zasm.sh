#!/usr/bin/env bash

# Calls emul/zasm/zasm in a convenient manner by wrapping specified
# paths to include in a single CFS file and then pass that file to zasm.
# Additionally, it takes a "-o" argument to set the initial ".org" of the
# binary. For example, "zasm.sh -o 4f < foo.asm" assembles foo.asm as if it
# started with the line ".org 0x4f00".

# The -a flag makes us switch to the AVR assembler

# readlink -f doesn't work with macOS's implementation
# so, if we can't get readlink -f to work, try python with a realpath implementation
ABS_PATH=$(readlink -f "$0" || python -c "import os; print(os.path.realpath('$0'))")
DIR=$(dirname "${ABS_PATH}")
ZASMBIN="${DIR}/zasm/zasm"

usage() { echo "Usage: $0 [-a] [-o <hexorg>] <paths-to-include>..." 1>&2; exit 1; }

org='00'
while getopts ":ao:" opt; do
    case "${opt}" in
        a)
            ZASMBIN="${DIR}/zasm/avra"
            ;;
        o)
            org=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# wrapper around ./zasm/zasm that prepares includes CFS prior to call
CFSPACK="${DIR}/../tools/cfspack/cfspack"
INCCFS=$(mktemp)

"${CFSPACK}" -p "*.h" -p "*.asm" -p "*.bin" "$@" > "${INCCFS}" 

"${ZASMBIN}" "${org}" "${INCCFS}"
RES=$?
rm "${INCCFS}"
exit $RES
