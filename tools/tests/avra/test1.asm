add r1, r31
ret
foo:
sleep
break
breq bar
asr r20
bar:
brbs 6, foo
ori r22, 0x34+4
sbrs r1, 3
rjmp	foo
rcall	baz
baz:
out	0x2e, r12
in	r0, 0x9
cbr	r31, 0xff
sbis	22, 5
ser	r19
bset	4
bclr	7
call	foo
jmp	bar
