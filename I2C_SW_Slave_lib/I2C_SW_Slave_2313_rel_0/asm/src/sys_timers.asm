/*
 * System Timer Utility - MOD's for Software I2C Slave testing
 *
 * org: 6/28/2014
 * rev: 03/26/2015
 * auth: Nels "Chip" Pearson
 *
 * Dependencies
 *	none
 *
 * Target: Any AVR
 *
 * Usage:
 * 	.include sys_timers.asm
 *
 */ 

; 1ms tic flags
;.equ					= GPIOR00		; Used by SW_I2C
;.equ					= GPIOR01		; Used by SW_I2C
;.equ					= GPIOR02		; 
;.equ					= GPIOR03		; 
; 10ms tic flags
;.equ					= GPIOR04		;
.equ	SWITCH_10MS_TIC	= GPIOR05		; Single Button and LED Service
;.equ					= GPIOR06		;
;.equ					= GPIOR07		;

.equ	SLOW_TIC		= 10			; 1ms * N for the slow tic

.DSEG
st_cnt_10ms:		.BYTE	1		; secondary timer counter.

.CSEG
/*
 * Set up Timer0 to generate 1ms and 10ms System Time Tics using 20MHz CPU clock.
 * GPIOR0 is used to provide TIC flags.
 * Call this once after RESET.
 *
 * Modifies: OCR0A, TCCR0A, TIMSK0, TCCR0B, and GPIOR0
 *
 * input reg:	none
 * output reg:	none
 * resources:	R16
 *
 * NOTE: 10ms and 1ms flags generated.
 *
 */
st_init_tmr0:
	ldi		R16, 77				; (20MHz) 2 * 256 * (1 + OCR0A) : 512 * (40*2) : 1024 * 40 * 2
	out		OCR0A, R16
	ldi		R16, (1<<WGM01)
	out		TCCR0A, R16
	ldi		R16, (1<<OCIE0A)
;;;	sts		TIMSK0, R16			; enable counter 0 OCO intr
	sts		TIMSK, R16			; enable counter 0 OCO intr
;
	ldi		R16, 0b100			; CPU div 256
	out		TCCR0B, R16
;
	ldi		R16, SLOW_TIC		; set for 10ms count.
	sts		st_cnt_10ms, R16
;
	clr		R16
	sts		GPIOR0, R16			; clear all tic flags
;
	ret

/*
 * Timer1 setup
 */

/*
 * Timer0 CTC (compare) interrupt service.
 * Called each 1ms
 *
 * input reg:	none
 * output reg:	none
 * resources:	GPIOR0.GPIR00:7
 * 				SRAM	1 byte
 *				Stack:3
 *
 */
st_tmr0_intr:
; DEBUG CODE +++
	sbi		PORTD, PORTD0
; DEBUG CODE ---
; tic1ms flags..don't affect SREG
	sbi		GPIOR0, GPIOR00		; Used by SW_I2C
	sbi		GPIOR0, GPIOR01		; Used by SW_I2C 
	sbi		GPIOR0, GPIOR02		; 
	sbi		GPIOR0, GPIOR03		;
;
; DEBUG CODE +++
	cbi		PORTD, PORTD0
; DEBUG CODE ---
	reti


st_tmr0org_intr:
; Save SREG
	push	R0
	in		R0, SREG
	push	R0
;
	push	R16
; tic1ms flags
	sbi		GPIOR0, GPIOR00		; Used by SW_I2C
	sbi		GPIOR0, GPIOR01		; Used by SW_I2C 
	sbi		GPIOR0, GPIOR02		; 
	sbi		GPIOR0, GPIOR03		;
;
	lds		R16, st_cnt_10ms	; get counter
	dec		R16
	brne	st_skip00
	ldi		R16, SLOW_TIC		; reload 10ms count down.
; tic10ms flags
	sbi		GPIOR0, GPIOR04		; 
	sbi		GPIOR0, GPIOR05		;
	sbi		GPIOR0, GPIOR06		; 
	sbi		GPIOR0, GPIOR07		;
;
st_skip00:
	sts		st_cnt_10ms, R16	; update
	pop		R16
; Restore SREG
	pop		R0
	out		SREG, R0
	pop		R0
;
	reti
