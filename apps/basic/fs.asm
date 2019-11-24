; FS-related basic commands

basFLS:
	ld	iy, .iter
	jp	fsIter
.iter:
	ld	a, FS_META_FNAME_OFFSET
	call	addHL
	call	printstr
	jp	printcrlf

basFSCmds:
	.dw	basFLS
	.db	"fls", 0, 0, 0
	.db	0xff, 0xff, 0xff	; end of table
