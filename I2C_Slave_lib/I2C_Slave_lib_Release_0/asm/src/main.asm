/*
 * I2C Slave Library Project
 *
 * org: 10/03/2014
 * auth: Nels "Chip" Pearson
 *
 * Target: R2 Link Board (ATmega164P) or LCD CDM-16100 Display (ATmega328P)
 *
 *
 * Slave Adrs: 0x57
 *
 */ 

.nolist
.include "m164pdef.inc"
;;;.include "m328pdef.inc"
.list


.ORG	$0000
	rjmp	RESET

.ORG	TWIaddr					; (0x34)
	rjmp	i2c_intr		; 2-wire Serial Interface
;
.ORG	INT_VECTORS_SIZE		; Skip over the rest of them.

.CSEG
RESET:
; setup SP
	ldi		R16, LOW(RAMEND)
	out		spl, R16
	ldi		R16, HIGH(RAMEND)
	out		sph, R16
; JTAG disable
	ldi		R16, $80
	out		MCUCR, R16
	out		MCUCR, R16
;
	call	i2c_init_slave		; init I2C interface as a Slave
	call	i2c_slave_init		; enable Slave
;
	sei							; enable intr
; TEST Data
	ldi		XL, LOW(i2c_buffer_out)
	ldi		XH, HIGH(i2c_buffer_out)
	ldi		R16, 0x11
	st		X+, R16
	lsl		R16				; 0x22
	st		X+, R16
	lsl		R16				; 0x44
	st		X+, R16
	lsl		R16				; 0x88
	st		X, R16
	ldi		R16, 4
	sts		i2c_buffer_out_cnt, R16
;
main:
;
m_skip00:
; TWEA = 0 will inhibit the Slave from responding to its address.
; simple I2C test
	lds		R16, i2c_buffer_out_cnt
	tst		R16							; check if output sent
	brne	main
;
	ldi		R16, 4
	sts		i2c_buffer_out_cnt, R16		; reset count
;
	rjmp	main


// I2C Slave code
.include "i2c_slave.asm"
