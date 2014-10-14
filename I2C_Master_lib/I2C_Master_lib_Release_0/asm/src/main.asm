/*
 * I2C Master Test Code
 *
 * org: 9/29/2014
 * auth: Nels "Chip" Pearson
 *
 * Platform: I2C Demo board
 *
 * Target: ATmega328/168/88/48 Atmel microcontroller, 1, 8, 20MHz
 *
 * Features
 * 1. I2C Master test code
 *
 * Resources
 * SRAM
 *
 * IO
 *
 *		C functions
 * r0			Not saved
 * r1			Zero
 * r2-r17		Saved
 * r18-r25		Not saved..Parameters r25:24, r23:22, r21:20, r19:18
 * r26-r27(X)	Not saved
 * r28-r29(Y)	Saved
 * r30-r31(Z)	Not saved
 *
 */ 

.nolist
;;;.include "m328pdef.inc"
.include "m164pdef.inc"
.list

.equ	LCD_SLAVE_ADRS	= (0x25)	; LCD CDM-16100 board
.equ	TONE_SLAVE_ADRS	= (0x57)	; Tone Demo Board


.ORG	$0000
	rjmp	RESET

.ORG	OC0Aaddr
;;;		rjmp	st_tmr0_intr	; TMR0 counter compare intr

.ORG	TWIaddr					; (0x34)
	rjmp	i2c_intr		; 2-wire Serial Interface

.ORG	INT_VECTORS_SIZE		; Skip over the rest of them.

.CSEG
RESET:
; setup Stack Pointer
	ldi		R16, LOW(RAMEND)
	out		spl, R16
	ldi		R16, HIGH(RAMEND)
	out		sph, R16
; JTAG disable
	ldi		R16, $80
	out		MCUCR, R16
	out		MCUCR, R16
; Initialize modules
	call	i2c_init_master		; Setup I2C Master Communication.
;
	sei							; enable interrupts.
;
	sbi		DDRC, PORTC4		; LED drive output.
;
	rjmp	main_m
;
main_m:
// TEST ++
	sbi		PORTC, PORTC4		; turn OFF LED
; Write Adrs->Data, ...->CKSUM
	ldi		R17, TONE_SLAVE_ADRS
	ldi		XL, LOW(i2c_buff_out)	; R26
	ldi		XH, HIGH(i2c_buff_out)	; R27
	ldi		R18, 2
	call	i2c_write
;
; WAIT a while
	ldi		R16, 0xA0
	clr		R17
m_loop0:
	dec		R17
	brne	m_loop0
	dec		R16
	brne	m_loop0
;
	cbi		PORTC, PORTC4		; turn ON LED
;
	ldi		R17, TONE_SLAVE_ADRS
	ldi		XL, LOW(i2c_buff_in)	; R26
	ldi		XH, HIGH(i2c_buff_in)	; R27
	ldi		R18, 4
;;;	call	i2c_read
;
; WAIT a while
	ldi		R16, 0xA0
	clr		R17
m_loop1:
	dec		R17
	brne	m_loop1
	dec		R16
	brne	m_loop1
// TEST --
;
	rjmp	main_m


// I2C Master Support
.include "i2c_master.asm"
// Small Packet Support
.include "packet_support.asm"
// Utilities
.include "utilities.asm"
// Bring in timmer support
;;;.include "sys_timers.asm"
