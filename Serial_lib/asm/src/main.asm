/*
 * Serial Library Test Code Project
 *
 * org: 12/14/2014
 * auth: Nels "Chip" Pearson
 *
 * Target: Tank Bot Demo Board, 20MHz, ATmega164P
 *
 *
 */ 

.nolist
.include "m164pdef.inc"
.list

.CSEG

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

.ORG	URXC1addr				; 0x38 USART1 RX complete
	rjmp	trap_intr

.ORG	UDRE1addr				; 0x3a USART1 Data Register Empty
	rjmp	trap_intr

.ORG	UTXC1addr				; 0x3c USART1 TX complete
	rjmp	trap_intr


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
	call	st_init_tmr0		; Set up Timer for general system tics.
	call	serial_init			; Initialze serial UART0.
;
	sei							; enable intr
;
main_m:
;
m_skip01:
	call	tb_serial			; send 'C' every 1000ms and echo back any character received.
;
	rjmp	main_m

trap_intr:
	rjmp	trap_intr

// Bring in timmer support
.include "sys_timers.asm"
// Board Test
.include "board_test.asm"
// RS-232 Serial Support
.include "serial_lib.asm"
// Fifo Support
.include "fifo_lib.asm"
