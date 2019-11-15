#!/usr/bin/env bash

# Calls tools/emul/zasm/zasm in a convenient manner by wrapping specified
# paths to include in a single CFS file and then pass that file to zasm.
# Additionally, it takes a "-o" argument to set the initial ".org" of the
# binary. For example, "zasm.sh -o 4f < foo.asm" assembles foo.asm as if it
# started with the line ".org 0x4f00".

# readlink -f doesn't work with macOS's implementation
# so, if we can't get readlink -f to work, try python with a realpath implementation
ABS_PATH=$(readlink -f "$0" || python -c "import os; print(os.path.realpath('$0'))")

usage() { echo "Usage: $0 [-o <hexorg>] <paths-to-include>..." 1>&2; exit 1; }

org='00'
while getopts ":o:" opt; do
    case "${opt}" in
        o)
            org=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

# wrapper around ./emul/zasm/zasm that prepares includes CFS prior to call
DIR=$(dirname "${ABS_PATH}")
ZASMBIN="${DIR}/emul/zasm/zasm"
CFSPACK="${DIR}/cfspack/cfspack"
INCCFS=$(mktemp)

for p in "$@"; do
    "${CFSPACK}" "${p}" "*.h" >> "${INCCFS}"    
    "${CFSPACK}" "${p}" "*.asm" >> "${INCCFS}"    
    "${CFSPACK}" "${p}" "*.bin" >> "${INCCFS}"    
done

"${ZASMBIN}" "${org}" "${INCCFS}"
RES=$?
rm "${INCCFS}"
exit $RES
