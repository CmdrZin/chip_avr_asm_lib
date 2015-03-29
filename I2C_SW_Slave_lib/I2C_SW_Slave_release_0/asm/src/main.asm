/*
 * I2C Software Slave Library Project
 *
 * org: 03/29/2015
 * rev:
 * auth: Nels "Chip" Pearson
 *
 * Target: I2C Demo Board
 *
 *
 * NOTE: Slave Adrs: 0x23 (set in i2c_slave_sw.asm)
 *
 */ 

.nolist
.include "m164pdef.inc"
.list


.ORG	$0000
	rjmp	RESET

.ORG	PCI2addr			; (0x0c) Pin Change Interrupt Request 2
	rjmp	portc_intr

.ORG	OC0Aaddr
	rjmp	trap_intr		; TMR0 counter compare intr

.ORG	TWIaddr				;
	rjmp	trap_intr
;
.ORG	INT_VECTORS_SIZE	; Don't code in vector table.

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
	call	i2c_init_sw_slave	; init I2C software interface as a Slave
	call	slave_core_init		; enable Slave and services.
;
	sei							; enable intr
;
main:
;
m_skip00:
;
	call	slave_core_service	; I2C command service
;
	call	i2c_sw_stop_det		; call at least every 1ms
;
	rjmp	main

/*
 * For Debug, trap any extrainious interrupts.
 */
trap_intr:
; put external debug trigger here or other indicator.
	rjmp	trap_intr

// I2C Slave code
.include "i2c_slave_sw.asm"
// FIFO support
.include "fifo_lib.asm"
// I2C Core Service
.include "i2c_slave_core.asm"
