/*
 * Stepper Motor Code
 *
 * org: 1/10/2015
 * auth: Nels "Chip" Pearson
 *
 * Target: I2C Demo Board, 20MHz, ATmega164P
 *
 * Dependentcies:
 *	sys_timers.asm
 *
 * Assumes 90 coils
 *       A
 *       B /
 *        C D
 *
 * rev: 14jan15 - Reset port at 1ms test to pulse motor coils instead of steady current to reduce power.
 *
 */

.equ	STEPPER_DELAY_COUNT	= 10			; min = 5..sets speed
.equ	STEPPER_ON_TIME_MS	= 5				; min = 5 for 5volt drive.

.equ	STEPPER_PHASE_STOP	= 16

.equ	STEPPER_ONE_REVOLUTION = 2039
;;.equ	STEPPER_ONE_REVOLUTION = 300


.equ	STEPPER_STATE_0	 = 0
.equ	STEPPER_STATE_1	 = 1
.equ	STEPPER_STATE_2	 = 2
.equ	STEPPER_STATE_3	 = 3
.equ	STEPPER_STATE_4	 = 4
.equ	STEPPER_STATE_5	 = 5
.equ	STEPPER_STATE_6	 = 6
.equ	STEPPER_STATE_7	 = 7
.equ	STEPPER_STATE_OFF = 8


.equ	STEPPER_DIR_STOP	= 0
.equ	STEPPER_DIR_FWD		= 1
.equ	STEPPER_DIR_REV		= 2

.equ	STEPPER_COIL_1	= PORTD0
.equ	STEPPER_COIL_2	= PORTD1
.equ	STEPPER_COIL_3	= PORTD2
.equ	STEPPER_COIL_4	= PORTD3

.equ	STEPPER_COIL_1b	= 0b00000001	; PORTD0
.equ	STEPPER_COIL_2b	= 0b00000010	; PORTD1
.equ	STEPPER_COIL_3b	= 0b00000100	; PORTD2
.equ	STEPPER_COIL_4b	= 0b00001000	; PORTD3

.DSEG
stepper_delay:		.BYTE	1			; service time delay * 10ms
stepper_state:		.BYTE	1			; last statre serviced..use dir for next state
stepper_direction:	.BYTE	1			; 0: Stop
stepper_speed:		.BYTE	1			; adj delay,,TODO
stepper_count:		.BYTE	2			; number of steps. dec back to zero. 100 is about 15 deg
stepper_duration:	.BYTE	1			; length of coil ON time in ms.


.CSEG
/*
 * Initialize Floor Service Parameters
 *
 * 
 */
stepper_init:
	call	stepper_init_io
;
	cbi		PORTD, STEPPER_COIL_1		; OFF
	cbi		PORTD, STEPPER_COIL_2		; OFF
	cbi		PORTD, STEPPER_COIL_3		; OFF
	cbi		PORTD, STEPPER_COIL_4		; OFF
;
	ldi		R16, STEPPER_DELAY_COUNT
	sts		stepper_delay, R16
;
	ldi		R16, STEPPER_STATE_0
	sts		stepper_state, R16
;
;;	ldi		r17, STEPPER_DIR_STOP
;;	ldi		r17, STEPPER_DIR_REV
	ldi		r17, STEPPER_DIR_FWD
	call	stepper_set_dir
;
	ldi		r16, 100
	sts		stepper_speed, r16				; TODO
;
	ldi		r16, low(STEPPER_ONE_REVOLUTION)
	sts		stepper_count, r16
	ldi		r16, high(STEPPER_ONE_REVOLUTION)
	sts		stepper_count+1, r16
;
	ret

/*
 * Initialize Floor Detector IO
 * 
 */
stepper_init_io:
; init IO output
	sbi		DDRD, STEPPER_COIL_1		; out
	sbi		DDRD, STEPPER_COIL_2		; out
	sbi		DDRD, STEPPER_COIL_3		; out
	sbi		DDRD, STEPPER_COIL_4		; out
;
	ret

/* *** TABLE LOOK-UP VERSION *** */

/* 
 * Use Data Look-up
 *   0		STOP
 *   1-4	FWD
 *   5-8	REV
 *
 * Copy value to PORT.
 * Optional: Use PORT service to mask bits and combine with PORT image.
 *
 * Advantages:	Execution time is constant.
 *				Less code.
 *				Easier to modify step sequence.
 *
 */

/*
 * stepper_service()
 *
 * Support biphase stepper motor
 *
 * Test 1ms flag..consume
 * if delay == 0
 * 	delay = 10
 * else
 * 	--delay then Exit
 * Service phase
 * Dec count and set back to STOP at 0.
 *
 */
stepper_service:
	sbis	GPIOR0, STEPPER_1MS_TIC	; test 1ms tic
	ret								; EXIT..not set
;
	cbi		GPIOR0, STEPPER_1MS_TIC	; clear tic10ms flag set by interrup
// Run service
	lds		r16, stepper_duration
	tst		r16
	breq	ssm_skip100				; already done?
	dec		r16
	sts		stepper_duration, r16
	brne	ssm_skip100
; Reset port to reduce power.
	clr		r17
	call	stp_update_io
;
ssm_skip100:
	lds		r16, stepper_delay
	dec		r16
	sts		stepper_delay, r16
	breq	ssm_skip00
	ret
;
ssm_skip00:
	ldi		r16, STEPPER_DELAY_COUNT
	sts		stepper_delay, r16
; Service Stepper Motor
	lds		r17, stepper_state
	andi	r17, 0x07				; limit range in case of glitch.
	call	stp_get_phase
	call	stp_update_io
; Update
	lds		r16, stepper_direction
	cpi		r16, STEPPER_DIR_FWD
	brne	ssm_skip10
; FWD
	lds		r16, stepper_state
	inc		r16
	cpi		r16, STEPPER_STATE_7	; last phase
	brsh	ssm_skip01
	rjmp	ssm_update
;
ssm_skip01:
	breq	ssm_update
	ldi		r16, STEPPER_STATE_0	; reset to beginning
	rjmp	ssm_update
;
ssm_skip10:
	cpi		r16, STEPPER_DIR_REV
	brne	ssm_skip20
; REV
	lds		r16, stepper_state
	cpi		r16, STEPPER_STATE_0
	breq	ssm_skip11
	dec		r16
	rjmp	ssm_update
;
ssm_skip11:
	ldi		r16, STEPPER_STATE_7	; reset to end
	rjmp	ssm_update

ssm_skip20:
; STOP
	lds		r16, stepper_state		; no change to state.
;
ssm_update:
	sts		stepper_state, r16
;
; Update count
	lds		r16, stepper_count
	lds		r17, stepper_count+1
	or		r17, r16
	breq	ssm_skip30				; done
;
	subi	r16, 1
	sts		stepper_count, r16
	clr		r17
	lds		r16, stepper_count+1
	sbc		r16, r17
	sts		stepper_count+1, r16
	rjmp	ssm_exit
;
ssm_skip30:
	ldi		r17, STEPPER_DIR_STOP
	call	stepper_set_dir
;
ssm_exit:
	ret

/*
 * input:	r17		Direction
 * output:	none
 */
stepper_set_dir:
	sts		stepper_direction, r17
	ret

/*
 * input:	r17		Phase pattern
 * output:	i/o
 */
stp_update_io:
	out		PORTD, r17
; set ON time
	ldi		r16, STEPPER_ON_TIME_MS
	sts		stepper_duration, r16
;
	ret

/*
 * input:	r17		Data	0, 1-8, 9-16
 * output:	r17		Phase pattern
 */

stp_get_phase:
	ldi		ZH, high(stepper_io_data<<1)	; Initialize Z pointer
	ldi		ZL, low(stepper_io_data<<1)
;
	clr		r16
	add		ZL, r17
	adc		ZH, r16
;
	lpm		R17, Z
;
	ret
;
/* 2 bytes per entry 0-7, 8-15, 16=STOP */
/* Keep 8 points to test with later. */
stepper_io_data:
.db		STEPPER_COIL_2b|STEPPER_COIL_1b, STEPPER_COIL_1b|STEPPER_COIL_4b	; BA, AD
.db		STEPPER_COIL_4b|STEPPER_COIL_3b, STEPPER_COIL_3b|STEPPER_COIL_2b	; DC, CB
.db		STEPPER_COIL_2b|STEPPER_COIL_1b, STEPPER_COIL_1b|STEPPER_COIL_4b	; BA, AD
.db		STEPPER_COIL_4b|STEPPER_COIL_3b, STEPPER_COIL_3b|STEPPER_COIL_2b	; DC, CB
.db		0x00, 0x00								; STOP

