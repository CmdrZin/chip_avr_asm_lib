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
 */

.equ	STEPPER_DELAY_COUNT	= 10			; min = 5

.equ	STEPPER_PHASE_STOP	= 16

.equ	STEPPER_FWD_PHASE_A	 = 0
.equ	STEPPER_FWD_PHASE_AC = 1
.equ	STEPPER_FWD_PHASE_C  = 2
.equ	STEPPER_FWD_PHASE_CB = 3
.equ	STEPPER_FWD_PHASE_B  = 4
.equ	STEPPER_FWD_PHASE_BD = 5
.equ	STEPPER_FWD_PHASE_D  = 6
.equ	STEPPER_FWD_PHASE_DA = 7

.equ	STEPPER_REV_PHASE_A  = 8
.equ	STEPPER_REV_PHASE_AD = 9
.equ	STEPPER_REV_PHASE_D  = 10
.equ	STEPPER_REV_PHASE_DB = 11
.equ	STEPPER_REV_PHASE_B  = 12
.equ	STEPPER_REV_PHASE_BC = 13
.equ	STEPPER_REV_PHASE_C  = 14
.equ	STEPPER_REV_PHASE_CA = 15

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
stepper_status:		.BYTE	1			; last phase serviced..use dir for next phase
stepper_direction:	.BYTE	1			; 0: Stop
stepper_speed:		.BYTE	1			; adj delay,,TODO


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
	ldi		R16, STEPPER_PHASE_STOP
	sts		stepper_status, R16
;
;;	ldi		r17, STEPPER_DIR_STOP
;;	ldi		r17, STEPPER_DIR_REV
	ldi		r17, STEPPER_DIR_FWD
	call	stepper_set_dir
;
	ldi		R16, 100
	sts		stepper_speed, R16				; TODO
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
 *
 */
stepper_service:
	sbis	GPIOR0, STEPPER_1MS_TIC	; test 1ms tic
	ret								; EXIT..not set
;
	cbi		GPIOR0, STEPPER_1MS_TIC	; clear tic10ms flag set by interrup
// Run service
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
;;	call	stepper_init_io				; restore IO
;
	lds		r17, stepper_status
	call	stp_get_phase
	call	stp_update_io
; Update
	
	lds		r16, stepper_direction
	cpi		r16, STEPPER_DIR_FWD
	brne	ssm_skip10
; FWD
	lds		r16, stepper_status
	inc		r16
	cpi		r16, STEPPER_FWD_PHASE_DA	; last phase
	brsh	ssm_skip01
	rjmp	ssm_update
;
ssm_skip01:
	breq	ssm_update
	ldi		r16, STEPPER_FWD_PHASE_A	; reset to beginning
	rjmp	ssm_update
;
ssm_skip10:
	cpi		r16, STEPPER_DIR_REV
	brne	ssm_skip20
; REV
	lds		r16, stepper_status
	inc		r16
	cpi		r16, STEPPER_REV_PHASE_CA	; last phase
	brsh	ssm_skip11
	rjmp	ssm_update
;
ssm_skip11:
	breq	ssm_update
	ldi		r16, STEPPER_REV_PHASE_A	; reset to beginning
	rjmp	ssm_update

ssm_skip20:
; STOP
	clr		r16
;
ssm_update:
	sts		stepper_status, r16
;
ssm_exit:
	ret

/*
 * input:	r17		Direction
 * output:	none
 */
stepper_set_dir:
	sts		stepper_direction, r17
; Inialize Phase Status
	cpi		r17, STEPPER_DIR_STOP
	brne	ssd_skip10
; STOP
	clr		r17
	rjmp	ssd_update
;
ssd_skip10:
	cpi		r17, STEPPER_DIR_FWD
	brne	ssd_skip20
; FORWARD
	ldi		r17, STEPPER_FWD_PHASE_A	; FWD-A
	rjmp	ssd_update
;
ssd_skip20:
	cpi		R17, STEPPER_DIR_REV
	brne	ssd_skip30
; REVERSE
	ldi		r17, STEPPER_REV_PHASE_A	; REV-A
	rjmp	ssd_update
;
ssd_skip30:
	ldi		R17, STEPPER_DIR_STOP	; default
	sts		stepper_direction, r17
	clr		r17
;
ssd_update:
	sts		stepper_status, r17
;
ssd_exit:
	ret

/*
 * input:	r17		Phase pattern
 * output:	i/o
 */
stp_update_io:
	out		PORTD, r17
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
stepper_io_data:
.db		STEPPER_COIL_2b|STEPPER_COIL_1b, STEPPER_COIL_1b|STEPPER_COIL_4b	; FWD-BA, FWD-AD
.db		STEPPER_COIL_4b|STEPPER_COIL_3b, STEPPER_COIL_3b|STEPPER_COIL_2b	; FWD-DC, FWD-CB
.db		STEPPER_COIL_2b|STEPPER_COIL_1b, STEPPER_COIL_1b|STEPPER_COIL_4b	; FWD-BA, FWD-AD
.db		STEPPER_COIL_4b|STEPPER_COIL_3b, STEPPER_COIL_3b|STEPPER_COIL_2b	; FWD-DC, FWD-CB

.db		STEPPER_COIL_1b|STEPPER_COIL_2b, STEPPER_COIL_2b|STEPPER_COIL_3b	; REV-AB, REV-BC
.db		STEPPER_COIL_3b|STEPPER_COIL_4b, STEPPER_COIL_4b|STEPPER_COIL_1b	; REV-CD, REV-DA
.db		STEPPER_COIL_1b|STEPPER_COIL_2b, STEPPER_COIL_2b|STEPPER_COIL_3b	; REV-AB, REV-BC
.db		STEPPER_COIL_3b|STEPPER_COIL_4b, STEPPER_COIL_4b|STEPPER_COIL_1b	; REV-CD, REV-DA

.db		0x00, 0x00								; STOP

