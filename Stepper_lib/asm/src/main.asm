/*
 * Seasons Clock Project
 *
 * org: 1/10/2015
 * auth: Nels "Chip" Pearson
 *
 * Target: I2C Demo Board, 20MHz, ATmega164P
 *
 *
 */ 

.nolist
.include "m164pdef.inc"
.list


.ORG	$0000
	rjmp	RESET
.ORG	$0002
	rjmp	trap_intr
.ORG	$0004
	rjmp	trap_intr
.ORG	$0006
	rjmp	trap_intr
.ORG	$0008
	rjmp	trap_intr
.ORG	$000A
	rjmp	trap_intr

.ORG	PCI2addr				; 0x0c Pin Change Interrupt Request 2
	rjmp	trap_intr
.ORG	$000E
	rjmp	trap_intr
.ORG	$0010
	rjmp	trap_intr

.ORG	OC2Aaddr				; 0x12 Timer/Counter2 Compare Match A
	rjmp	trap_intr
.ORG	$0014
	rjmp	trap_intr
.ORG	$0016
	rjmp	trap_intr
.ORG	$0018
	rjmp	trap_intr

.ORG	OC1Aaddr				; 0x1a Timer/Counter1 Compare Match A
	rjmp	trap_intr

.ORG	OC1Baddr				; 0x1c Timer/Counter1 Compare Match B
	rjmp	trap_intr
.ORG	$001E
	rjmp	trap_intr

.ORG	OC0Aaddr				; 0x20 Timer/Counter0 Compare Match A
	rjmp	st_tmr0_intr
.ORG	$0022
	rjmp	trap_intr
.ORG	$0024
	rjmp	trap_intr
.ORG	$0026
	rjmp	trap_intr
.ORG	$0028
	rjmp	trap_intr
.ORG	$002A
	rjmp	trap_intr
.ORG	$002C
	rjmp	trap_intr
.ORG	$002E
	rjmp	trap_intr
.ORG	$0030
	rjmp	trap_intr
.ORG	$0032
	rjmp	trap_intr

.ORG	TWIaddr					; 0x34 2-wire Serial Interface
	rjmp	trap_intr
.ORG	$0036
	rjmp	trap_intr
.ORG	$0038
	rjmp	trap_intr
.ORG	$003A
	rjmp	trap_intr
.ORG	$003C
	rjmp	trap_intr


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
	call	st_init_tmr0
	call	stepper_init		; set up stepper I/O and state.
;
	sei							; enable intr
;
main_m:
;
	call	stepper_service
;
m_skip01:
;
	rjmp	main_m

trap_intr:
;	call	tb_led3_on
	rjmp	trap_intr

// Sys Timer support
.include "sys_timers.asm"
// Stepper Motor support
.include "stepper_motor.asm"
