.inc "user.h"

	ld	hl, sAwesome
	call	printstr
	xor	a		; success
	ret

sAwesome:
	.db	"Assembled from a TRS-80", 0x0d, 0


