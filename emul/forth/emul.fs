( Implementation fo KEY and EMIT in the emulator
  stdio port is 0
)

CODE EMIT
    HL POPqq,
    chkPS,
    A L LDrr,
    0 OUTnA,
;CODE

CODE KEY
    0 INAn,
    H 0 LDrn,
    L A LDrr,
    HL PUSHqq,
;CODE
