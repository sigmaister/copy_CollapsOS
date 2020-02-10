# TRS-80 Model 4p

## Ports

    Address     Read                    Write
    FC-FF       Cassette in             Cassette out, resets
    F8-FB       Rd printer status       Wr to printer
    F4-F7       -                       Drive select
    F3          FDC data reg            FDC data reg
    F2          FDC sector reg          FDC sector reg
    F1          FDC track reg           FDC track reg
    F0          FDC status reg          FDC cmd reg
    EC-EF       Reset RTC INT           Mode output
    EB          RS232 recv holding reg  RS232 xmit holding reg
    EA          UART status reg         UART/modem control
    E9          -                       Baud rate register
    E8          Modem status            Master reset/enable
                                        UART control reg
    E4-E7       Rd NMI status           Wr NMI mask reg
    E0-E3       Rd INT status           Wr INT mask reg
    CF          HD status               HD cmd
    CE          HD size/drv/hd          HD size/drv/hd
    CD          HD cylinder high        HD cylinder high
    CC          HD cylinder low         HD cylinder low
    CB          HD sector #             HD sector #
    CA          HD sector cnt           HD sector cnt
    C9          HD error reg            HD write precomp
    C8          HD data reg             HD data reg
    C7          HD CTC chan 3           HD CTC chan 3
    C6          HD CTC chan 2           HD CTC chan 2
    C5          HD CTC chan 1           HD CTC chan 1
    C4          HD CTC chan 0           HD CTC chan 0
    C2-C3       HD device ID            -
    C1          HD control reg          HD Control reg
    C0          HD wr prot reg          -
    94-9F       -                       -
    90-93       -                       Sound option
    8C-8F       Graphic sel 2           Graphic sel 2
    8B          CRTC Data reg           CRTC Data reg
    8A          CRTC Control reg        CRTC Control reg
    89          CRTC Data reg           CRTC Data reg
    88          CRTC Control reg        CRTC Control reg
    84-87       -                       Options reg
    83          -                       Graphic X reg
    82          -                       Graphic Y reg
    81          Graphics RAM            Graphics RAM
    80          -                       Graphics options reg

    Bit map

    Address     D7      D6      D5      D4      D3      D2      D1      D0
    F8-FB-Rd    Busy    Paper   Select  Fault   -       -       -       -
    EC-EF-Rd    (any read causes reset of RTC interrupt)
    EC-EF-Wr    -       CPU     -       Enable  Enable  Mode    Cass    -
                        Fast            EX I/O  Altset  Select  Mot on
    E0-E3-Rd    -       Recv    Recv    Xmit    10 Bus  RTC     C Fall  C Rise
                        Error   Data    Empty   int     Int     Int     Int
    E0-E3-Wr    -       Enable  Enable  En.Xmit Enable  Enable  Enable  Enable
                        Rec err Rec dat Emp     10 int  RTC int CF int  CR int
    90-93-Wr    -       -       -       -       -       -       -       Sound
                                                                        Bit
    84-87-Wr    Page    Fix upr Memory  Memory  Invert  80/64   Select  Select
                        mem     bit 1   bit 0   video           Bit 1   Bit 0

## System memory map

### Memory map 1 - model III mode

    0000-1fff       ROM A (8K)
    2000-2fff       ROM B (4K)
    3000-37ff       ROM C (2K) - less 37e8/37e9
    37e8-37e9       Printer Status Port
    3800-3bff       Keyboard
    3c00-3fff       Video RAM (page bit selects 1K or 2K)
    4000-7fff       RAM (16K system)
    4000-ffff       RAM (64K system)

### Memory map 2

    0000-37ff       RAM (14K)
    3800-3bff       Keyboard
    3c00-3fff       Video RAM
    4000-7fff       RAM (16K) end of one 32K bank
    8000-ffff       RAM (32K) second 32K bank

### Memory map 3

    0000-7fff       RAM (32K) bank 1
    8000-f3ff       RAM (29K) bank 2
    f400-f7ff       Keyboard
    f800-ffff       Video RAM
    
### Memory map 4

    0000-7fff       RAM (32K) bank 1
    8000-ffff       RAM (32K) bank 2

## TRSDOS memory map

    0000-25ff       Reserved for TRSDOS operations
    2600-2fff       Overlay area
    3000-HIGH       Free to use
    HIGH-ffff       Drivers, filters, etc

    Use `MEMORY` command to know value of `HIGH`

## Supervisor calls

SVC are made by loading the correct SVC number in A, other params in other regs,
and then call `rst 0x28`.

Z is pretty much always used for success or as a boolean indicator. It is
sometimes not specified when there's not enough tabular space, but it's there.
When `-` is specified, it means that the routine either never returns or is
always successful.

    Num Name    Args                Res  Desc
    00  IPL     -                   -    Reboot the system
    01  KEY     -                   AZ   Scan *KI, wait for char
    02  DSP     C=char              AZ   Display character
    03  GET     DE=F/DCB            AZ   Get one byte from device or file
    04  PUT     DE=F/DCB C=char     AZ   Write one byte to device or file
    05  CTL     DE=DBC C=func       CAZ  Output a control byte
    06  PRT     C=char              AZ   Send character to printer
    07  WHERE   -                   HL   Locate origin of SVC
    08  KBD     -                   AZ   Scan keyboard and return
    09  KEYIN   HL=buf b=len c=0    HLBZ Accept a line of input
    0a  DSPLY   HL=str              AZ   Display message line
    0b  LOGER   HL=str              AZ   Issue log message
    0c  LOGOT   HL=str              AZ   Display and log message
    0d  MSG     DE=F/DCB HL=str     AZ   Send message to device
    0e  PRINT   HL=str              AZ   Print message line
    0f  VDCTL   special             spc  Video functions
    10  PAUSE   BC=delay            -    Suspend program execution
    11  PARAM   DE=ptbl HL=str      Z    Parse parameter string
    12  DATE    HL=recvbuf          HLDE Get date
    13  TIME    HL=recvbuf          HLDE Get time
    14  CHNIO   IX=DCB B=dir C=char -    Pass control to next module in device chain
    15  ABORT   -                   -    Abort Program
    16  EXIT    HL=retcode          -    Exit to TRSDOS
    18  CMNDI   HL=cmd              -    Exec Cmd w/ return to system
    19  CMNDR   HL=cmd              HL   Exec Cmd
    1a  ERROR   C=errno             -    Entry to post an error message
    1b  DEBUG   -                   -    Enter DEBUG
    1c  CKTSK   C=slot              Z    Check if task slot in use
    1d  ADTSK   C=slot              -    Remove interrupt level task
    1e  RMTSK   DE=TCB C=slot       -    Add an interrupt level task
    1f  RPTSK   -                   -    Replace task vector
    20  KLTSK   -                   -    Remove currently executing task
    21  CKDRV   C=drvno             Z    Check drive
    22  DODIR   C=drvno b=func      ZBHL Do directory display/buffer
    23  RAMDIR  HL=buf B=dno C=func AZ   Get directory record or free space
    28  DCSTAT  C=drvno             Z    Test if drive assigned in DCT
    29  SLCT    C=drvno             AZ   Select a new drive
    2a  DCINIT  C=drvno             AZ   Initialize the FDC
    2b  DCRES   C=drvno             AZ   Reset the FDC
    2c  RSTOR   C=drvno             AZ   Issue a FDC RESTORE command
    2d  STEPI   C=drvno             AZ   Issue a FDC STEP IN command
    2e  SEEK    C=drvno DE=addr     -    Seek a cylinder
    2f  RSLCT   C=drvno             -    Test for drive busy
    30  RDHDR   HL=buf DCE=addr     AZ   Read a sector header
    31  RDSEC   HL=buf DCE=addr     AZ   Read a sector 
    32  VRSEC   DCE=addr            AZ   Verify sector
    33  RDTRK   HL=buf DCE=addr     AZ   Read a track 
    34  HDFMT   C=drvno             AZ   Hard disk format
    35  WRSEC   HL=buf DCE=addr     AZ   Write a sector 
    36  WRSSC   HL=buf DCE=addr     AZ   Write system sector 
    37  WRTRK   HL=buf DCE=addr     AZ   Write a track 
    38  RENAM   DE=FCB HL=str       AZ   Rename file
    39  REMOV   DE=D/FCB            AZ   Remove file or device
    3a  INIT    HL=buf DE=FCB B=LRL AZ   Open or initialize file
    3b  OPEN    HL=buf DE=FCB B=LRL AZ   Open existing file or device
    3c  CLOSE   DE=FCB/DCB          AZ   Close a file or device
    3d  BKSP    DE=FCB              AZ   Backspace one logical record
    3e  CKEOF   DE=FCB              AZ   Check for EOF
    3f  LOC     DE=FCB              BCAZ Calculate current logical record number
    40  LOF     DE=FCB              BCAZ Calculate the EOF logical record number
    41  PEOF    DE=FCB              AZ   Position to end of file
    42  POSN    DE=FCB BC=LRN       AZ   Position file
    43  READ    DE=FCB HL=ptr       AZ   Read a record
    44  REW     DE=FCB              AZ   Rewind file to beginning
    45  RREAD   DE=FCB              AZ   Reread sector
    46  RWRIT   DE=FCB              AZ   Rewrite sector
    47  SEEKSC  DE=FCB              -    Seek cylinder and sector of record
    48  SKIP    DE=FCB              AZ   Skip a record
    49  VER     DE=FCB              HLAZ Write and verify a record
    4a  WEOF    DE=FCB              AZ   Write end of file
    4b  WRITE   DE=FCB HL=ptr       AZ   Write a record
    4c  LOAD    DE=FCB              HLAZ Load program file
    4d  RUN     DE=FCB              HLAZ Run program file
    4e  FSPEC   HL=buf DE=F/DCB     HLDE Assign file or device specification
    4f  FEXT    DE=FCB HL=str       -    Set up default file extension
    50  FNAME   DE=buf B=DEC C=drv  AZHL Get filename
    51  GTDCT   C=drvno             IY   Get drive code table address
    52  GTDCB   DE=devname          HLAZ Get device control block address
    53  GTMOD   DE=modname          HLDE Get memory module address
    55  RDSSC   HL=buf DCE=addr     AZ   Read system sector 
    57  DIRRD   B=dirent C=drvno    HLAZ Directory record read
    58  DIRWR   B=dirent C=drvno    HLAZ Directory record write
    5a  MUL8    C*E                 A    Multiply C by E
    5b  MUL16   HL*C                HLA  Multiply HL by C
    5d  DIV8    E/C                 AE   Divides E by C
    5e  DIV16   HL/C                HLA  Divides HL by C
    60  DECHEX  HL=str              BCHL Convert Decimal ASCII to binary
    61  HEXDEC  HL=num DE=buf       DE   Convert binary to decimal ASCII
    62  HEX8    C=num HL=buf        HL   Convert 1 byte to hex ASCII
    53  HEX16   DE=num HL=buf       HL   Convert 2 bytes to hex ASCII
    64  HIGH$   B=H/L HL=get/set    HLAZ Get or Set HIGH$/LOW$
    65  FLAGS   -                   IY   Point IY to system flag table
    66  BANK    B=func C=bank       BZ   Memory bank use
    67  BREAK   HL=vector           HL   Set Break vector
    68  SOUND   B=func              -    Sound generation
