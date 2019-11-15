.equ	FS_MAX_NAME_SIZE	0x1a
.equ	FS_BLOCKSIZE		0x100
.equ	FS_METASIZE		0x20

.equ	FS_META_ALLOC_OFFSET	3
.equ	FS_META_FSIZE_OFFSET	4
.equ	FS_META_FNAME_OFFSET	6
; Size in bytes of a FS handle:
; * 4 bytes for starting offset of the FS block
; * 2 bytes for file size
.equ	FS_HANDLE_SIZE		6
.equ	FS_ERR_NO_FS		0x5
.equ	FS_ERR_NOT_FOUND	0x6
