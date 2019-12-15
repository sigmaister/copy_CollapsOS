; TODO: implement instructions that are commented out
; REGISTER USAGE
;
; R1: overflow counter
; R16: tmp stuff

.inc "avr.h"
.inc "tn254585.h"
.inc "tn45.h"

main:
	ldi	r16, RAMEND&0xff
        out	SPL, r16
        ldi	r16, RAMEND}8
	out	SPH, r16

        ;sbi     DDRB, 0
        ;cbi     PORTB, 0

	; To have a blinking delay that's visible, we have to prescale a lot.
	; The maximum prescaler is 1024, which makes our TCNT0 increase
	; 976 times per second, which means that it overflows 4 times per
	; second.
        in      r16, TCCR0B
        ori     r16, 0x05	; CS00 + CS02 = 1024 prescaler
        out     TCCR0B, r16

	clr	r1

loop:
	in	r16, TIFR	; TIFR0
	sbrc	r16, 1		; is TOV0 flag clear?
	rcall	toggle
        rjmp    loop

toggle:
	ldi	r16, 0b00000010	; TOV0
	out	TIFR, R16
	inc	r1
        ;cbi     PORTB, 0
        sbrs    r1, 1		; if LED is on
        ;sbi     PORTB, 0
	ret
