/*
 * Stepper Motor Code
 *
 * org: 1/10/2015
 * auth: Nels "Chip" Pearson
 *
 * Target: I2C Demo Board, 20MHz, ATmega164P
 *
 *
 */

.equ	STEPPER_DELAY_COUNT	= 10

.equ	STEPPER_PHASE_A	= 0
.equ	STEPPER_PHASE_B	= 1
.equ	STEPPER_PHASE_C	= 2
.equ	STEPPER_PHASE_D	= 3

.equ	STEPPER_DIR_STOP	= 0
.equ	STEPPER_DIR_FWD		= 1
.equ	STEPPER_DIR_REV		= 2

.equ	STEPPER_COIL_1	= PORTD0
.equ	STEPPER_COIL_2	= PORTD1
.equ	STEPPER_COIL_3	= PORTD2
.equ	STEPPER_COIL_4	= PORTD3


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
	ldi		R16, STEPPER_PHASE_A
	sts		stepper_status, R16
;
;;	ldi		R16, STEPPER_DIR_STOP
;;	ldi		R16, STEPPER_DIR_REV
	ldi		R16, STEPPER_DIR_FWD
	sts		stepper_direction, R16
;
	ldi		R16, 100
	sts		stepper_speed, R16
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

/*
 * stepper_service()
 *
 * Support biphase stepper motor
 *
 * Test 10ms flag..consume
 * if delay == 0
 * 	delay = 10
 * else
 * 	--delay then Exit
 * Check Direction: STOP, FWD, REV
 * Set next phase
 *
 */
stepper_service:
	sbis	GPIOR0, STEPPER_1MS_TIC	; test 10ms tic
	ret								; EXIT..not set
;
	cbi		GPIOR0, STEPPER_1MS_TIC	; clear tic10ms flag set by interrup
// Run service
	lds		R16, stepper_delay
	dec		R16
	sts		stepper_delay, R16
	breq	ssm_skip00
	ret
;
ssm_skip00:
	ldi		R16, STEPPER_DELAY_COUNT
	sts		stepper_delay, R16
; Service Stepper Motor
	call	stepper_init_io				; restore IO
;
	lds		R16, stepper_direction
;
	cpi		R16, STEPPER_DIR_STOP
	brne	ssm_skip10
; STOP
	call	stepper_stop
	rjmp	ssm_exit					; EXIT
;
ssm_skip10:
	cpi		R16, STEPPER_DIR_FWD
	brne	ssm_skip20
; FORWARD Phase Sequence
	call	stepper_fwd
	rjmp	ssm_exit					; EXIT
;
ssm_skip20:
	cpi		R16, STEPPER_DIR_REV
	brne	ssm_skip30
; REVERSE Phase Sequence
	call	stepper_rev
	rjmp	ssm_exit					; EXIT
;
ssm_skip30:
	ldi		R16, STEPPER_DIR_STOP		; default
	sts		stepper_direction, R16
;
ssm_exit:
	ret


/*
 * Stepper FWD
 */
stepper_fwd:
	lds		R16, stepper_status			; get phase
; switch(phase)
	cpi		R16, STEPPER_PHASE_A
	brne	smf_skip11
; A -> B
	cbi		PORTD, STEPPER_COIL_1
	sbi		PORTD, STEPPER_COIL_2
	ldi		R16, STEPPER_PHASE_B
	rjmp	smf_update
;
smf_skip11:
	cpi		R16, STEPPER_PHASE_B
	brne	smf_skip12
; B -> C
	cbi		PORTD, STEPPER_COIL_3
	sbi		PORTD, STEPPER_COIL_4
	ldi		R16, STEPPER_PHASE_C
	rjmp	smf_update
;
smf_skip12:
	cpi		R16, STEPPER_PHASE_C
	brne	smf_skip13
; C -> D
	sbi		PORTD, STEPPER_COIL_1
	cbi		PORTD, STEPPER_COIL_2
	ldi		R16, STEPPER_PHASE_D
	rjmp	smf_update
;
smf_skip13:
	cpi		R16, STEPPER_PHASE_D
	brne	smf_skip30
; D -> A
	sbi		PORTD, STEPPER_COIL_3
	cbi		PORTD, STEPPER_COIL_4
	ldi		R16, STEPPER_PHASE_A
	rjmp	smf_update
;
smf_skip30:
	ldi		R16, STEPPER_PHASE_A	; default
;
smf_update:
	sts		stepper_status, R16
;
smf_exit:
	ret

/*
 * Stepper REV
 */
stepper_rev:
	lds		R16, stepper_status			; get phase
; switch(phase)
	cpi		R16, STEPPER_PHASE_A
	brne	smr_skip21
; A -> D
	cbi		PORTD, STEPPER_COIL_3
	sbi		PORTD, STEPPER_COIL_4
	ldi		R16, STEPPER_PHASE_D
	rjmp	smr_update
;
smr_skip21:
	cpi		R16, STEPPER_PHASE_D
	brne	smr_skip22
; D -> C
	cbi		PORTD, STEPPER_COIL_1
	sbi		PORTD, STEPPER_COIL_2
	ldi		R16, STEPPER_PHASE_C
	rjmp	smr_update
;
smr_skip22:
	cpi		R16, STEPPER_PHASE_C
	brne	smr_skip23
; C -> B
	sbi		PORTD, STEPPER_COIL_3
	cbi		PORTD, STEPPER_COIL_4
	ldi		R16, STEPPER_PHASE_B
	rjmp	smr_update
;
smr_skip23:
	cpi		R16, STEPPER_PHASE_B
	brne	smr_skip30
; B -> A
	sbi		PORTD, STEPPER_COIL_1
	cbi		PORTD, STEPPER_COIL_2
	ldi		R16, STEPPER_PHASE_A
	rjmp	smr_update
;
smr_skip30:
	ldi		R16, STEPPER_PHASE_A	; default

smr_update:
	sts		stepper_status, R16
;
smr_exit:
	ret


/*
 * Stepper STOP
 */
stepper_stop:
	cbi		PORTD, STEPPER_COIL_1
	cbi		PORTD, STEPPER_COIL_2
	cbi		PORTD, STEPPER_COIL_3
	cbi		PORTD, STEPPER_COIL_4
	ret									; EXIT
