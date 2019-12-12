EMULDIR = ../emul
CFSPACK = ../cfspack/cfspack

.PHONY: run
run:
	$(MAKE) -C $(EMULDIR) zasm/zasm runbin/runbin shell/shell
	cd unit && ./runtests.sh
	cd zasm && ./runtests.sh
	cd shell && ./runtests.sh

$(CFSPACK):
	$(MAKE) -C ../cfspack

.PHONY: cfs
cfs: $(CFSPACK)
	$(CFSPACK) shell/cfsin > shell/test.cfs
