# TI-83+/TI-84+

Texas Instruments is well known for its calculators. Among those, two models
are particularly interesting to us because they have a z80 CPU: the TI-83+ and
TI-84+ (the "+" is important).

They lack accessible I/O ports, but they have plenty of flash and RAM. Collapse
OS runs on it (see `recipes/ti84`).

I haven't opened one up yet, but apparently, they have limited scavenging value
because its z80 CPU is packaged in a TI-specific chip. Due to its sturdy design,
and its ample RAM and flash, we could imagine it becoming a valuable piece of
equipment if found intact.

The best pre-collapse ressource about it is
[WikiTI](http://wikiti.brandonw.net/index.php).

## Getting software on it

Getting software to run on it is a bit tricky because it needs to be signed
with TI-issued private keys. Those keys have long been found and are included
in `recipes/ti84`. With the help of the
[mktiupgrade](https://github.com/KnightOS/mktiupgrade), an upgrade file can be
prepared and then sent through the USB port with the help of
[tilp](http://lpg.ticalc.org/prj_tilp/).

That, however, requires a modern computing environment. As of now, there is no
way of installing Collapse OS on a TI-8X+ calculator from another Collapse OS
system.

Because it is not on the roadmap to implement complex cryptography in Collapse
OS, the plan is to build a series of pre-signed bootloader images. The
bootloader would then receive data through either the Link jack or the USB port
and write that to flash (I haven't verified that yet, but I hope that data
written to flash this way isn't verified cryptographically by the calculator).

As modern computing fades away, those pre-signed binaries would become opaque,
but at least, would allow bootstrapping from post-modern computers.
