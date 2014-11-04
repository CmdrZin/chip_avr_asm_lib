/*
 * FIFO Example Code
 *
 * org: 11/03/2014
 * auth: Nels "Chip" Pearson
 *
 * Target: ATmega164P
 *
 * Basis for evaluating FIFO utility
 *
 */ 

.nolist
.include "m164pdef.inc"
.list


.def	TEMP 		= R16


.ORG	$0000
	rjmp	RESET


.CSEG
RESET:
; setup SP
	ldi		TEMP, LOW(RAMEND)
	out		spl, TEMP
	ldi		TEMP, HIGH(RAMEND)
	out		sph, TEMP
; JTAG disable
	ldi		TEMP, $80
	out		MCUCR, TEMP
	out		MCUCR, TEMP
;
	ldi		r21, 0x30
;
main:
	ldi		XL, LOW(ser_in_buff)
	ldi		XH, HIGH(ser_in_buff)
	ldi		r19, SER_BUFF_SIZE
	mov		r17, r21
	inc		r21
	call	fifo_put
	mov		r17, r21
	inc		r21
	call	fifo_put
	mov		r17, r21
	inc		r21
	call	fifo_put
;
	ldi		XL, LOW(ser_in_buff)
	ldi		XH, HIGH(ser_in_buff)
	ldi		r19, SER_BUFF_SIZE
	call	fifo_get
	call	fifo_get
	call	fifo_get
m001:
;
	rjmp	main


// FIFO Library
.include "fifo_lib.asm"
