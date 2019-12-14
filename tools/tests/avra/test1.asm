add r1, r31
ret
foo:
sleep
break
breq bar
asr r20
bar:
brbs 6, foo
