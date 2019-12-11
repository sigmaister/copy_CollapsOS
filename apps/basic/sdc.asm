; SDC-related basic commands

basSDCI:
	jp	sdcInitializeCmd

basSDCF:
	jp	sdcFlushCmd

basSDCCmds:
	.db	"sdci", 0
	.dw	basSDCI
	.db	"sdcf", 0
	.dw	basSDCF
	.db	0xff		; end of table
