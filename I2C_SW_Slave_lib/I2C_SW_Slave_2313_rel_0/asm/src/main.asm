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
 * include path
 * 	D:\Program Files (x86)\Atmel\Atmel Toolchain\AVR Assembler\Native\2.1.1117\avrassembler\include
 *
 */ 

.nolist
.include "tn2313Adef.inc"
.list


.ORG	$0000
	rjmp	RESET

.ORG	PCIBaddr			; (0x0b) Pin Change Interrupt Request B
	rjmp	portc_intr

.ORG	PCIDaddr			; (0x14) Pin Change Interrupt Request D
	rjmp	portc_intr
;


;;.ORG	INT_VECTORS_SIZE	; Don't code in vector table.

.CSEG
RESET:
; setup SP
	ldi		R16, LOW(RAMEND)
	out		spl, R16
; no SPH
; JTAG disable
	ldi		R16, $80
	out		MCUCR, R16
	out		MCUCR, R16
;
	rcall	i2c_init_sw_slave	; init I2C software interface as a Slave
	rcall	slave_core_init		; enable Slave and services.
;
	rcall	turn_led_off		; DEBUG CODE
;
;;	ldi		r16, (1<<PCIE_I2C)
;;	out		GIMSK, r16
;
;;	ldi		r16, SW_SDA_EN		; (1<<PCINT_SCL)		; 0x40
;;	out		PCMSK, r16
;
	sei							; enable intr
;
main:
;
m_skip00:
;
	rcall	slave_core_service	; I2C command service
;
	rcall	i2c_sw_stop_det		; call at least every 1ms
;
	rjmp	main

/*
 * For Debug, trap any extrainious interrupts.
 */
trap_intr:
; put external debug trigger here or other indicator.
	rcall	turn_led_on
;
	rjmp	trap_intr

; DEBUG CODE ++
turn_led_on:
	sbi		DDRD, PORTD0
	sbi		PORTD, PORTD0
	ret

turn_led_off:
	sbi		DDRD, PORTD0
	cbi		PORTD, PORTD0
	ret
; DEBUG CODE --



// I2C Slave code
.include "i2c_slave_sw.asm"
// FIFO support
.include "fifo_lib.asm"
// I2C Core Service
.include "i2c_slave_core.asm"

