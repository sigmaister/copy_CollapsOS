EMULDIR = ../emul

.PHONY: run
run:
	$(MAKE) -C $(EMULDIR) zasm/zasm runbin/runbin
	cd unit && ./runtests.sh
	cd zasm && ./runtests.sh
