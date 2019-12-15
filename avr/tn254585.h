; *** Registers ***

.equ	SREG	0x3f
.equ	SPH	0x3e
.equ	SPL	0x3d
.equ	GIMSK	0x3b
.equ	GIFR	0x3a
.equ	TIMSK	0x39
.equ	TIFR	0x38
.equ	SPMCSR	0x37
.equ	MCUCR	0x35
.equ	MCUSR	0x34
.equ	TCCR0B	0x33
.equ	TCNT0	0x32
.equ	OSCCAL	0x31
.equ	TCCR1	0x30
.equ	TCNT1	0x2f
.equ	OCR1A	0x2e
.equ	OCR1C	0x2d
.equ	GTCCR	0x2c
.equ	OCR1B	0x2b
.equ	TCCR0A	0x2a
.equ	OCR0A	0x29
.equ	OCR0B	0x28
.equ	PLLCSR	0x27
.equ	CLKPR	0x26
.equ	DT1A	0x25
.equ	DT1B	0x24
.equ	DTPS	0x23
.equ	DWDR	0x22
.equ	WDTCR	0x21
.equ	PRR	0x20
.equ	EEARH	0x1f
.equ	EEARL	0x1e
.equ	EEDR	0x1d
.equ	EECR	0x1c
.equ	PORTB	0x18
.equ	DDRB	0x17
.equ	PINB	0x16
.equ	PCMSK	0x15
.equ	DIDR0	0x14
.equ	GPIOR2	0x13
.equ	GPIOR1	0x12
.equ	GPIOR0	0x11
.equ	USIBR	0x10
.equ	USIDR	0x0f
.equ	USISR	0x0e
.equ	USICR	0x0d
.equ	ACSR	0x08
.equ	ADMUX	0x07
.equ	ADCSRA	0x06
.equ	ADCH	0x05
.equ	ADCL	0x04
.equ	ADCSRB	0x03


; *** Interrupt vectors ***

.equ	INT0addr	0x0001	; External Interrupt 0
.equ	PCI0addr	0x0002	; Pin change Interrupt Request 0
.equ	OC1Aaddr	0x0003	; Timer/Counter1 Compare Match 1A
.equ	OVF1addr	0x0004	; Timer/Counter1 Overflow
.equ	OVF0addr	0x0005	; Timer/Counter0 Overflow
.equ	ERDYaddr	0x0006	; EEPROM Ready
.equ	ACIaddr		0x0007	; Analog comparator
.equ	ADCCaddr	0x0008	; ADC Conversion ready
.equ	OC1Baddr	0x0009	; Timer/Counter1 Compare Match B
.equ	OC0Aaddr	0x000a	; Timer/Counter0 Compare Match A
.equ	OC0Baddr	0x000b	; Timer/Counter0 Compare Match B
.equ	WDTaddr		0x000c	; Watchdog Time-out
.equ	USI_STARTaddr	0x000d	; USI START
.equ	USI_OVFaddr	0x000e	; USI Overflow

.equ	INT_VECTORS_SIZE	15	; size in words
