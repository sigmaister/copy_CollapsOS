#/usr/bin/env bash

set -e

git submodule init
git submodule update
git clean -fxd

cd tools/emul
make

cd ../tests
make

# let's try again with an updated zasm
cd ../emul
make updatebootstrap all

cd ../tests
make
