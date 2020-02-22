; floppy-related basic commands

basFLUSH:
	jp	floppyFlush

basFloppyCmds:
	.db	"flush", 0
	.dw	basFLUSH
	.db	0xff		; end of table

