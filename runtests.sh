#/bin/sh -e

git submodule init
git submodule update
git clean -fxd

make -C tools/emul
make -C tests

# let's try again with an updated zasm
make -C tools/emul updatebootstrap all
make -C tests
