EMULDIR = ../emul

.PHONY: run
run:
	$(MAKE) -C $(EMULDIR) zasm/zasm runbin/runbin shell/shell
	cd unit && ./runtests.sh
	cd zasm && ./runtests.sh
	cd shell && ./runtests.sh
