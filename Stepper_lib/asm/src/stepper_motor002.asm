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
	ldi		R16, STEPPER_DIR_STOP
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

/* TABLE LOOK-UP VERSION */

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
	lds		R16, stepper_delay
	dec		R16
	sts		stepper_delay, R16
; Service Stepper Motor
	call	stepper_init_io				; restore IO
;
	lds		r17, stepper_status
	call	stp_get_phase
	call	stp_update_io
;
	ret

/*
 * input:	r17		Direction
 * output:	none
 */
stepper_set_dir:
	lds		r16, stepper_direction
	cpi		r16, STEPPER_DIR_STOP
	brne	ssd_skip10
; STOP
	clr		r16
	rjmp	ssd_update
;
ssd_skip10:
	cpi		r16, STEPPER_DIR_FWD
	brne	ssd_skip20
; FORWARD
	ldi		r16, 1					; FWD-A
	rjmp	ssd_update
;
ssd_skip20:
	cpi		R16, STEPPER_DIR_REV
	brne	ssd_skip30
; REVERSE
	ldi		r16, 5					; REV-C
	rjmp	ssd_update
;
ssd_skip30:
	ldi		R16, STEPPER_DIR_STOP	; default
	sts		stepper_direction, r16
	rjmp	ssd_exit				; EXIT
;
ssd_update:
	sts		stepper_status, R16
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
 * input:	r17		Data	0, 1-4, 5-8
 * output:	r17		Phase pattern
 */

stp_get_phase:
	ldi		ZH, high(stepper_io_data<<1)	; Initialize Z pointer
	ldi		ZL, low(stepper_io_data<<1)
;
	lsl		r17								; add index
	clr		r16
	add		ZL, r17
	adc		ZH, r16
;
	lpm		R17, Z
;
	ret
;
/* 2 bytes per entry */
stepper_io_data:
;       STOP     FWD-A       FWD-B       FWD-C       FWD-D       REV-C       REV-B       REV-A       REV-D
.db		0x00, 0b00000110, 0b00001010, 0b00001001, 0b00000101, 0b00001001, 0b00001010, 0b00000110, 0b00000101, 0x00
