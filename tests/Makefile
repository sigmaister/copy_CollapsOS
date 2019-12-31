EMULDIR = ../tools/emul
CFSPACK = ../tools/cfspack/cfspack

.PHONY: run
run:
	$(MAKE) -C $(EMULDIR) zasm/zasm zasm/avra runbin/runbin shell/shell
	cd unit && ./runtests.sh
	cd zasm && ./runtests.sh
	cd avra && ./runtests.sh
	cd shell && ./runtests.sh

$(CFSPACK):
	$(MAKE) -C ../tools/cfspack

.PHONY: cfs
cfs: $(CFSPACK)
	$(CFSPACK) shell/cfsin > shell/test.cfs
