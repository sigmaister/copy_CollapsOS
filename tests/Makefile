EMULDIR = ../emul

.PHONY: run
run:
	$(MAKE) -C $(EMULDIR) forth/forth
	cd forth && ./runtests.sh
