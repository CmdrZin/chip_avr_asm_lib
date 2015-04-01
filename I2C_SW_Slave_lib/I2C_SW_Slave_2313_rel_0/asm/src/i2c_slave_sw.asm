/*
 * I2C Software Slave Interface - For ATtiny2313A
 *
 * org: 03/25/2015
 * rev: 03/29/2015
 * auth: Nels "Chip" Pearson
 *
 * This is a software I2C Slave interface using pin change interrupts.
 * NOTE: NO other interrupts can be used due to tight timing requirements.
 *		 Use POLLING of intr flags instead.
 *
 * This implementation uses a common FIFO utility to buffer input and output data.
 *
 * i2c_status is used to tell the app what is happening or has happened on the I2C bus.
 *	I2C Status values:
 *		I2C_STATUS_IDLE			- Waiting for START condition
 *		I2C_STATUS_RECEIVING	- Receiving data from Master
 *		I2C_STATUS_MSG_RCVD		- A STOP occured while receiving data.
 *								- Received bytes are in i2c_in_fifo.
 *								- Can read data while r18 returns as 0(valid data) (see FIFO API)
 *		I2C_STATUS_SENDING		- Sending data to Master
 *
 * Usage:
 * 	.include i2c_slave_sw.asm
 *
 * Dependencies:
 *	.include fifo_lib.asm
 *
 * Limitations:
 *	Uses dedicated registers: R10 -> R15 for speed.
 *	CPU clock of 20MHz required for processing at 100kHz I2C. Slower clock can be used if slower I2C clock.
 *	NO other interrupts can be used due to critical code timing to respond to SCL edges.
 *	i2c_sw_stop_det must be called fast enough to occur before next Master SLA transmission.
 *
 */ 

.equ	I2C_DEMO_SLAVE_ADRS	= (0x23)
.equ	LCD_SLAVE_ADRS		= (0x25)
.equ	TONE_SLAVE_ADRS		= (0x56)
.equ	SLAVE_ADRS 			= I2C_DEMO_SLAVE_ADRS	// Set to desired address for Slave.

/*
 * These equates define the IO pin and registers to use.
 * They MUST be defined to match the pins being used.
 * The interrupt vector (see main.asm) will also need to be changed if PORTC is not used.
 *
 * NOTE: Only PORTB is available on 2313. A&D are on 2313A.
 *
 */
// IO Pins
.equ	SW_SCL_OUT	= PORTB3
.equ	SW_SDA_OUT	= PORTB4
.equ	SW_SCL_IN	= PINB3
.equ	SW_SDA_IN	= PINB4
// IO Ports
.equ	SW_SCL_PORT	= PORTB
.equ	SW_SDA_PORT	= PORTB
// IO Read PORT
.equ	SW_SCL_PIN	= PINB
.equ	SW_SDA_PIN	= PINB
// IO DDRs
.equ	SW_SCL_DDR	= DDRB
.equ	SW_SDA_DDR	= DDRB
// and their interrupt control bits.
.equ	PCINT_SCL	= PCINT3
.equ	PCINT_SDA	= PCINT4
.equ	PCMSK_I2C	= PCMSK				; PCMSK0 not defined.
;
.equ	PCIE_I2C	= PCIE				; text uses PCIE0, but not in .inc file

// Masks
.equ	SW_SCL_EN	= (1<<PCINT_SCL)	; OR this
.equ	SW_SCL_DIS	= ~SW_SCL_EN	; AND this
.equ	SW_SDA_EN	= (1<<PCINT_SDA)
.equ	SW_SDA_DIS	= ~SW_SDA_EN


// I2C Error values
.equ	I2C_ERROR_NONE			= 0x00		// No errors
.equ	I2C_ERROR_OV			= 0x01		// Overflow on input buffer.

// I2C Status values..DO NOT CHANGE THESE..TIED TO sw_i2c_mode for optimization.
.equ	I2C_STATUS_IDLE			= 0x20
.equ	I2C_STATUS_RECEIVING	= SW_I2C_MODE_READ
.equ	I2C_STATUS_MSG_RCVD		= 0x02				; Rec'd message in buffer.
.equ	I2C_STATUS_SENDING		= SW_I2C_MODE_WRITE

.equ	I2C_BUFFER_SIZE			= 18

.DSEG
// Matches FIFO_LIB data struct for buffers.
i2c_buffer_in:			.BYTE	I2C_BUFFER_SIZE
i2c_in_fifo_head:		.BYTE	1
i2c_in_fifo_tail:		.BYTE	1

i2c_buffer_out:			.BYTE	I2C_BUFFER_SIZE
i2c_out_fifo_head:		.BYTE	1
i2c_out_fifo_tail:		.BYTE	1

i2c_status:				.BYTE	1			; I2C status byte. 

.CSEG
/*
 * Initialize Software support for I2C Slave interface.
 * input reg:	none
 * output reg:	none
 *
 * PCICR = (1<<PCIE2)
 * PCMSK2 = 0x03 to enable as intr
 *
 * SCL - Pin change interrupt 16 (PC0)
 * SDA - Pin change interrupt 17 (PC1)
 *
 */
i2c_init_sw_slave:
; set pins as inputs
	sbi		SW_SCL_PORT, SW_SCL_OUT		; enable weak pull-up
	cbi		SW_SCL_DDR, SW_SCL_OUT
	sbi		SW_SDA_PORT, SW_SDA_OUT		; enable weak pull-up
	cbi		SW_SDA_DDR, SW_SDA_OUT
; enable pin interrupts for SDA line.
	in		r16, PCMSK_I2C				; lds/sts doesn't work for 2313.
	ori		r16, SW_SDA_EN				; After START, disable SDA and enable SCL.
	out		PCMSK_I2C, r16
; init bus state machine
	ldi		r16, SW_I2C_START_WAIT
	mov		r_i2c_state, r16
; set Slave address
	ldi		r16, SLAVE_ADRS
	sts		sw_i2c_twar, r16
; set mode to look for address data after START
	ldi		r16, SW_I2C_MODE_WSTART
	mov		r_i2c_mode, r16
	ldi		r16, SW_I2C_SMODE_WADRS
	mov		r_i2c_sub_mode, r16
; clear STOP arm
	clr		r16
	mov		r_i2c_stop_arm, r16
; prep FIFOs
	clr		r16
	sts		i2c_in_fifo_head, r16
	sts		i2c_in_fifo_tail, r16
	sts		i2c_out_fifo_head, r16
	sts		i2c_out_fifo_tail, r16
;
	ret

/*
 * Initialize for SLAVE I2C interface.
 * Called by slave_core_init()
 *
 * input reg:	none
 * output reg:	none
 */
i2c_slave_start:
	ldi		r16, I2C_STATUS_IDLE
	sts		i2c_status, r16
; enable I2C interrupts
	in		r16, GIMSK				; lds/sts doesn't work for 2313.
	ldi		r17, (1<<PCIE_I2C)
	or		r16, r17
	out		GIMSK, r16
;
	ret


// START STOP Detector
/*
 * Poll from the main fast loop.
 *
 * Armed when SCL.L>H and SDA.L
 * SCL.H>L (interrupt controlled) will disarm.
 *
 */
i2c_sw_stop_det:
	mov		r16, r_i2c_stop_arm
	tst		r16
	breq	issd_exit					; no test
; was armed on SDA.L..SCL.L will  disarm.
	sbis	SW_SDA_PIN, SW_SDA_IN
	rjmp	issd_exit
; still armed?
	mov		r16, r_i2c_stop_arm
	tst		r16
	breq	issd_exit					; no test
	mov		r16, r_i2c_stop_arm
	tst		r16
	breq	issd_exit					; no test
; STOP detected
// DEBUG ++
;;;	cbi		DEBUG_PORT, DEBUG_SDA
// DEBUG --
	clr		r16
	mov		r_i2c_stop_arm, r16			; clear ARM
; disable SCL, enable SDA
;;;	lds		r16, PCMSK_I2C				; doesn't work on 2313
	in		r16, PCMSK_I2C
	andi	r16, SW_SCL_DIS
	ori		r16, SW_SDA_EN
;;;	sts		PCMSK_I2C, r16				; doesn't work on 2313
	out		PCMSK_I2C, r16
; init bus state machine
	ldi		r16, SW_I2C_START_WAIT
	mov		r_i2c_state, r16
; set I2C Status
	lds		r16, i2c_status
	cpi		r16, I2C_STATUS_RECEIVING
	breq	issd_skip00
; no
	ldi		r16, I2C_STATUS_IDLE
	rjmp	issd_skip01
;
issd_skip00:
	ldi		r16, I2C_STATUS_MSG_RCVD
;
issd_skip01:
	sts		i2c_status, r16
;
issd_exit:
	ret



// Bus state..ignores not sent to process.
.equ	SW_I2C_SCL_L		= 0			; SCL,L and only SCL enabled.
.equ	SW_I2C_SCL_H		= 1			; SCL.H and both enabled.
.equ	SW_I2C_START_WAIT	= 2			; wait for SDA.L

.equ	SW_I2C_MODE_READ	= 0			; BUS is SENDING data to Slave
.equ	SW_I2C_MODE_WRITE	= 1			; BUS is REQUESTING data from Slave
.equ	SW_I2C_MODE_WSTART	= 2			; waiting for START

.equ	SW_I2C_SMODE_WADRS		= 1		; waiting for Slave Address data
.equ	SW_I2C_SMODE_WDATA		= 2		; waiting for data
.equ	SW_I2C_SMODE_WADRS_ACK	= 3		; waiting for Slave Address data ACK to be read
.equ	SW_I2C_SMODE_WDATA_ACK	= 4		; waiting for data ACK to be read

.equ	SW_I2C_SCL_L_1		= 11		; wait for SCL.L to send address ACK.
.equ	SW_I2C_SCL_L_2		= 12		; wait for SCL.L to send data ACK.
.equ	SW_I2C_SCL_L_3		= 13		; wait for SCL.L to send
.equ	SW_I2C_SCL_L_4		= 14		; wait for SCL.L to send
.equ	SW_I2C_SCL_L_5		= 15		; wait for SCL.L to send

.def	r_i2c_state		= r15			; bus SCL state
.def	r_i2c_bit_cnt	= r14			; counts data bits recv'd or sent.
.def	r_i2c_buff		= r13			; data buffer.
.def	r_i2c_mode		= r12			; _W or _R mode
.def	r_i2c_sub_mode	= r11			; sub mode
.def	r_i2c_stop_arm	= r10			; STOP filter

.DSEG
sw_i2c_twar:		.BYTE	1			; Slave address.. SLA_x

.CSEG
/*
 * PortC Interrupt Service
 *
 * This interrupt service routine determines the edge of SCL and passes it to the I2C mode service.
 * It also detects a START conditions.
 *
 * PCICR = (1<<PCIE2)
 * PCMSK2 = 0x03 to enable as intr
 *
 * SCL - Pin change interrupt 16 (PC0)
 * SDA - Pin change interrupt 17 (PC1)
 *
 * Any changes to these lines invokes a state machine to simulate the TWI hardware.
 * Since the Master supplies the clock, this machine will step in sync if the CPU clock is => 20MHz.
 *
 * SW_I2C_SCL_L			- looking for SCL,L>H
 * SW_I2C_SCL_H			- looking for SCL.H>L
 * SW_I2C_START_WAIT	- only SDA enabled. wait for SDA.L with SCL.H
 *
 */
portc_intr:
; DEBUG CODE +++
;;;	sbi		PORTD, PORTD0
; DEBUG CODE ---

; Save SREG
	push	R0
	in		R0, SREG
	push	R0
;
	push	r16
	push	r17
;
; get state
	mov		r16, r_i2c_state
; switch(sw_i2c_state)
	cpi		r16, SW_I2C_SCL_H
	breq	pi_skip01
	cpi		r16, SW_I2C_SCL_L
	breq	pi_skip00
	cpi		r16, SW_I2C_START_WAIT
	breq	pi_skip02

; default
	ldi		r16, SW_I2C_START_WAIT
	mov		r_i2c_state, r16
	rjmp	pi_exit
;
; case SW_I2C_SCL_L:			Only SCL is enabled, so this has to be a SCL.L -> SCL.H
pi_skip00:
	sbis	SW_SCL_PIN, SW_SCL_IN
	rjmp	pi_exit				; ignore if LOW
; Arm STOP detect if SDA.L
	sbic	SW_SDA_PIN, SW_SDA_IN
	rjmp	pi_skip000
; Arm STOP detect
	ser		r16
	mov		r_i2c_stop_arm, r16
	rjmp	pi_skip001
;
pi_skip000:
; else Disarm STOP detect if SDA.H
	clr		r_i2c_stop_arm			; OPTIMIZATION
;
pi_skip001:
; set state to SW_I2C_SCL_H(1)
	inc		r_i2c_state				; OPTIMIZATION since state = 0 to get here.
	mov		r17, r_i2c_state
;
	rcall	i2c_mode_service		; gets passed r17
	rjmp	pi_exit
;
; case SW_I2C_SCL_H:
pi_skip01:
; SCL.L edge detected
; Disarm STOP detect
	clr		r17
	mov		r_i2c_stop_arm, r17
;
;set state = SW_I2C_SCL_L(0)		 OPTIMIZATION
	mov		r_i2c_state, r17
;
	rcall	i2c_mode_service		; gets passed r17
	rjmp	pi_exit
;
; SCL.H still
pi_skip010:
	rjmp	pi_exit
;
; case SW_I2C_START_WAIT			Only SDA is enabled to look for H>L
pi_skip02:
	sbic	SW_SDA_PIN, SW_SDA_IN	; check for SDA.L
	rjmp	pi_exit					; nope..EXIT
;
; SCL should be HIGH..
	sbis	SW_SCL_PIN, SW_SCL_IN
	rjmp	pi_exit					; no?..ignore this intr
;
; START detected
; Disable SDA..enable SCL
;;;	lds		r16, PCMSK_I2C			; doesn't work for 2313
	in		r16, PCMSK_I2C
	andi	r16, SW_SDA_DIS
	ori		r16, SW_SCL_EN
;;;	sts		PCMSK_I2C, r16
	out		PCMSK_I2C, r16			; doesn't work for 2313
;
	ldi		r17, SW_I2C_SCL_H
	mov		r_i2c_state, r17
; set ARM to test for STOP
	ser		r16
	mov		r_i2c_stop_arm, r16
; set up bit count
	ldi		r16, 8
	mov		r_i2c_bit_cnt, r16
;
	ldi		r16, SW_I2C_MODE_READ
	mov		r_i2c_mode, r16
;
	ldi		r16, SW_I2C_SMODE_WADRS
	mov		r_i2c_sub_mode, r16
;
	rjmp	pi_exit
;
pi_exit:
	pop		r17
	pop		r16
; Restore SREG
	pop		R0
	out		SREG, R0
	pop		R0
;
; DEBUG CODE +++
;;;	cbi		PORTD, PORTD0
; DEBUG CODE ---
	reti


/*
 * I2C Mode Service - I2C state machine
 *
 * r16 & r17 have been pushed on to stack by calling routine.
 * r17 = bus state..SW_I2C_SCL_L, SW_I2C_SCL_H, or SW_I2C_START
 *
 * READ:
 *	SW_I2C_SCL_L_1				- wait for SCL.L to check mode _R, _W
 *	SW_I2C_SMODE_WADRS			- Collect bits for Slave address on SCL.H
 *	SW_I2C_SMODE_WDATA			- Collect bits for data on SCL.H
 *	SW_I2C_SMODE_WADRS_ACK		- waiting for SLA ACK to be read on SCL.H
 *	SW_I2C_SMODE_WDATA_ACK		- waiting for Data ACK to be read on SCL.H
 *	SW_I2C_SCL_L_2				- waiting for SCL.L for SLA ACK
 *	SW_I2C_SCL_L_3				- waiting for Data clock SCL.L to send ACK
 *	SW_I2C_SCL_L_4				- waiting for SCL.L from ACK read, stretch clock, save data
 *
 * WRITE:
 *	SW_I2C_SMODE_WDATA			- writing out data
 *	SW_I2C_SCL_L_1				- waiting for SCL.L to set ACK
 *	SW_I2C_SMODE_WADRS_ACK		- waiting for SLA ACK to be read on SCL.H
 *	SW_I2C_SMODE_WDATA_ACK		- waiting for data ACK to be read..SCL.H
 *	SW_I2C_SCL_L_2				- waiting for SCL.L on SLA ACK, stretch clock, load data
 *	SW_I2C_SCL_L_3				- wait to read data bit on SCL.H
 *	SW_I2C_SCL_L_4				- wait for SCL.L on DATA ACK, stretch clock, load data
 *
 */
i2c_mode_service:
; get mode
	mov		r16, r_i2c_mode
; switch(sw_i2c_mode)
	cpi		r16, SW_I2C_MODE_WRITE
	brne	ims_skip0
	rjmp	ims_write_service
;
ims_skip0:
	cpi		r16, SW_I2C_MODE_READ
	brne	ims_skip1
	rjmp	ims_read_service
;
ims_skip1:
	cpi		r16, SW_I2C_MODE_WSTART
	brne	ims_skip2
	rjmp	ims_exit				; ignore everythnig until START sets mode to READ.
;
ims_skip2:
	rjmp	ims_exit
;
/* *** READ SERVICE - BUS is SENDING data to Slave ***/
; case SW_I2C_MODE_READ:			READ in Master's data
ims_read_service:
	mov		r16, r_i2c_sub_mode
; switch(sw_i2c_sub_mode)
	cpi		r16, SW_I2C_SCL_L_1
	brne	irs_skip000
	rjmp	irs_skip01
;
irs_skip000:
	cpi		r16, SW_I2C_SMODE_WADRS
	brne	irs_skip001
	rjmp	irs_skip02
;
irs_skip001:
	cpi		r16, SW_I2C_SMODE_WDATA
	brne	irs_skip006
	rjmp	irs_skip03
;
irs_skip006:
	cpi		r16, SW_I2C_SCL_L_4
	brne	irs_skip002
	rjmp	irs_skip08
;
irs_skip002:
	cpi		r16, SW_I2C_SMODE_WADRS_ACK
	brne	irs_skip003
	rjmp	irs_skip04
;
irs_skip003:
	cpi		r16, SW_I2C_SMODE_WDATA_ACK
	brne	irs_skip004
	rjmp	irs_skip05
;
irs_skip004:
	cpi		r16, SW_I2C_SCL_L_2
	brne	irs_skip005
	rjmp	irs_skip06
;
irs_skip005:
	cpi		r16, SW_I2C_SCL_L_3
	brne	irs_skip099
	rjmp	irs_skip07
;
irs_skip099:
	rjmp	ims_exit
;

; case SW_I2C_SCL_L_1:			wait for SCL.L to check mode _R, _W
irs_skip01:
	cpi		r17, SW_I2C_SCL_L
	brne	irs_skip010
; check address after getting SCL.L on clock 8.
	mov		r16, r_i2c_buff
	lsr		r16					; get rid of _R, _W bit
	lds		r17, sw_i2c_twar	; get Slave address
	cp		r16, r17
	brne	irs_skip011
; Address match..check _W, _R bit
; set ACK
	cbi		SW_SDA_PORT, SW_SDA_OUT
	sbi		SW_SDA_DDR, SW_SDA_OUT		; set as output for ACK.
; get Mode
	lsr		r_i2c_buff					; move mode (_R=1 _W=0 Master's action) bit into CY
	brcs	irs_skip012
	ldi		r16, SW_I2C_MODE_READ		; BUS is SENDING data to Slave
; set I2C Status
	sts		i2c_status, r16				; I2C_STATUS_RECEIVING = SW_I2C_MODE_READ
;
	rjmp	irs_skip013
;
irs_skip012:
	ldi		r16, SW_I2C_MODE_WRITE		; BUS is REQUESTING data from Slave
; set I2C Status
	sts		i2c_status, r16				; I2C_STATUS_SENDING = SW_I2C_MODE_WRITE
;
irs_skip013:
	mov		r_i2c_mode, r16				; set mode..0=W..1=R
;
	ldi		r16, SW_I2C_SMODE_WADRS_ACK		; wait for SCL.H to read ACK.
	mov		r_i2c_sub_mode, r16
	rjmp	ims_exit
;
irs_skip011:
; not matched..send NACK which is do nothing..reset back to waiting for START.
	ldi		r16, SW_I2C_MODE_WSTART
	mov		r_i2c_mode, r16
	rjmp	ims_exit
;
irs_skip010:
	rjmp	ims_exit
;
; case SW_I2C_SMODE_WADRS:	Collect bits for Slave address. Looking for SW_I2C_SCL_H
irs_skip02:
	cpi		r17, SW_I2C_SCL_H
	breq	irs_skip020
	rjmp	ims_exit
;
irs_skip020:
	sbic	SW_SDA_PIN, SW_SDA_IN	; read pin
	rjmp	irs_skip021
;
; bit = 0
	clc							; clear CY
	rjmp	irs_skip022
;
; bit = 1
irs_skip021:
	sec
;
irs_skip022:
	rol		r_i2c_buff			; update data
; check count
	dec		r_i2c_bit_cnt
	breq	irs_skip023
	rjmp	ims_exit
;
; check address after getting SCL.L
irs_skip023:
	ldi		r16, SW_I2C_SCL_L_1			; Only READ needs to service this sub_mode
	mov		r_i2c_sub_mode, r16
;
	rjmp	ims_exit

; case SW_I2C_SMODE_WDATA			Collect bit for data..looking for SCL.H
irs_skip03:
	cpi		r17, SW_I2C_SCL_H
	breq	irs_skip030
	rjmp	ims_exit
;
irs_skip030:
; test SDA
	sbic	SW_SDA_PIN, SW_SDA_IN
	rjmp	irs_skip031
; bit = 0
	clc							; clear CY
	rjmp	irs_skip032
;
irs_skip031:					; bit = 1
	sec
irs_skip032:
	rol		r_i2c_buff			; update data
; check count
	dec		r_i2c_bit_cnt
	breq	irs_skip033
	rjmp	ims_exit
;
; save data and wait to ACK
irs_skip033:
; Date read..need to wait for SCL.L to send ACK
	ldi		r16, SW_I2C_SCL_L_3
	mov		r_i2c_sub_mode, r16
;
	rjmp	ims_exit
;
; case SW_I2C_SMODE_WADRS_ACK:	Wait for adrs ACK to be read..looking for SW_I2C_SCL_H
irs_skip04:
	cpi		r17, SW_I2C_SCL_H
	breq	irs_skip040
	rjmp	ims_exit
;
; SCL edge has read ACK..wait for SCL.L
irs_skip040:
	ldi		r16, SW_I2C_SCL_L_2
	mov		r_i2c_sub_mode, r16
;
	rjmp	ims_exit

;
; case SW_I2C_SMODE_WDATA_ACK:	Wait for data ACK to be read.
irs_skip05:
	cpi		r17, SW_I2C_SCL_H
	breq	irs_skip050
	rjmp	ims_exit
;
; SCL edge has read ACK..wait for SCL.L to save data with clock stretch
irs_skip050:
	ldi		r16, SW_I2C_SCL_L_4
	mov		r_i2c_sub_mode, r16
;
	rjmp	ims_exit

;
; case SW_I2C_SCL_L_2:			Waiting for SCL.L on ACK
irs_skip06:
	cpi		r17, SW_I2C_SCL_L
	breq	irs_skip060
	rjmp	ims_exit
;
; SCL.L edge has completed ACK..set SDA back to input and continue on to READ data.
irs_skip060:
	cbi		SW_SDA_DDR, SW_SDA_OUT
	sbi		SW_SDA_PORT, SW_SDA_OUT			; enable weak pull-up.
;
	ldi		r16, SW_I2C_SMODE_WDATA
	mov		r_i2c_sub_mode, r16
; load counter
	ldi		r16, 8
	mov		r_i2c_bit_cnt, r16
;
	rjmp	ims_exit

; case SW_I2C_SCL_L_3:			Waiting for SCL.L from data to send ACK
irs_skip07:
	cpi		r17, SW_I2C_SCL_L
	breq	irs_skip070
	rjmp	ims_exit
;
irs_skip070:
	sbi		SW_SDA_DDR, SW_SDA_OUT
	cbi		SW_SDA_PORT, SW_SDA_OUT			; set ACK
; wait for ACK to be read
	ldi		r16, SW_I2C_SMODE_WDATA_ACK
	mov		r_i2c_sub_mode, r16
	rjmp	ims_exit

;
; case SW_I2C_SCL_L_4:			Waiting for SCL.L from ACK read, stretch clock, save data
irs_skip08:
	cpi		r17, SW_I2C_SCL_L
	breq	irs_skip080
	rjmp	ims_exit
;
irs_skip080:
; OK to release SDA here
	cbi		SW_SDA_DDR, SW_SDA_OUT			; set as input
; setting SCL.L to stretch clock.
	sbi		SW_SCL_DDR, SW_SCL_OUT			; set as output
	cbi		SW_SCL_PORT, SW_SCL_OUT
; save data
	rcall	i2c_sw_save_buff
; reload counter
	ldi		r16, 8
	mov		r_i2c_bit_cnt, r16
; release SCL to end strecth
	cbi		SW_SCL_DDR, SW_SCL_OUT			; set as input
; get more data
	ldi		r16, SW_I2C_SMODE_WDATA
	mov		r_i2c_sub_mode, r16
	rjmp	ims_exit


/* *** WRITE SERVICE - BUS is REQUESTING data from Slave *** */
; case SW_I2C_MODE_WRITE:					WRITE back data to Master.
ims_write_service:
	mov		r16, r_i2c_sub_mode
; switch(sw_i2c_sub_mode)
	cpi		r16, SW_I2C_SMODE_WDATA			; writing out data
	brne	iws_skip000
	rjmp	iws_skip03
;
iws_skip000:
	cpi		r16, SW_I2C_SCL_L_1				; waiting for SCL.L to set ACK
	brne	iws_skip002
	rjmp	iws_skip01

iws_skip002:
	cpi		r16, SW_I2C_SMODE_WADRS_ACK
	brne	iws_skip003
	rjmp	iws_skip04
;
iws_skip003:
	cpi		r16, SW_I2C_SMODE_WDATA_ACK		; waiting for last data sent to be ACK'd
	brne	iws_skip004
	rjmp	iws_skip05
;
iws_skip004:
	cpi		r16, SW_I2C_SCL_L_2				; waiting for SCL.L after address ACK
	brne	iws_skip005
	rjmp	iws_skip06
;
iws_skip005:
	cpi		r16, SW_I2C_SCL_L_3				; waiting for SCL.H on Data bit
	brne	iws_skip006
	rjmp	iws_skip07
;
iws_skip006:
	cpi		r16, SW_I2C_SCL_L_4				; waiting for SCL.L after Data ACK
	brne	iws_skip099
	rjmp	iws_skip08
;
iws_skip099:
; error..out of sync..go back to waiting for START.
	ldi		r16, SW_I2C_MODE_WSTART
	mov		r_i2c_mode, r16
;
	rjmp	ims_exit

;
; case SW_I2C_SCL_L_1:		wait for SCL.L to send ACK
iws_skip01:
	cpi		r17, SW_I2C_SCL_L
	breq	iws_skip010
	rjmp	ims_exit
;
iws_skip010:
	sbi		SW_SDA_DDR, SW_SDA_OUT
	cbi		SW_SDA_PORT, SW_SDA_OUT		; set ACK
;
	ldi		r16, SW_I2C_SMODE_WADRS_ACK		; wait for SCL.H to read ACK.
	mov		r_i2c_sub_mode, r16
	rjmp	ims_exit


; case SW_I2C_SMODE_WDATA:			Sending out the other 7 bits from buffer.
iws_skip03:
	cpi		r17, SW_I2C_SCL_L
	breq	iws_skip030
	rjmp	ims_exit
;
; SCL edge has read bit.
iws_skip030:
	dec		r_i2c_bit_cnt
	breq	iws_skip033
; not done yet
	lsl		r_i2c_buff					; get next bit
	brcc	iws_skip031
;
	sbi		SW_SDA_PORT, SW_SDA_OUT		; set to 1 if CY=1
	rjmp	ims_exit
;
iws_skip031:
	cbi		SW_SDA_PORT, SW_SDA_OUT		; clear to 0
	rjmp	ims_exit
;
; ALL bits sent..relese SDA, and go test ACK.
iws_skip033:
;
	cbi		SW_SDA_DDR, SW_SDA_OUT				; set as input to detect ACK from Master.
;
	ldi		r16, SW_I2C_SMODE_WDATA_ACK
	mov		r_i2c_sub_mode, r16
	rjmp	ims_exit

;
; Wait for SLA ACK to be read by Master.
; case SW_I2C_SMODE_WADRS_ACK:				Looking for SW_I2C_SCL_H. Cannot release SDA until SLC.L
iws_skip04:
	cpi		r17, SW_I2C_SCL_H
	breq	iws_skip040
	rjmp	ims_exit
;
; Master has read address ACK
iws_skip040:
	ldi		r16, SW_I2C_SCL_L_2
	mov		r_i2c_sub_mode, r16
;
	rjmp	ims_exit

;
; case SW_I2C_SMODE_WDATA_ACK:			Wait to read data ACK. SDA released.
iws_skip05:
	cpi		r17, SW_I2C_SCL_H
	breq	iws_skip050
	rjmp	ims_exit
;
; Slave has read Master's ACK/NACK
iws_skip050:
	sbic	SW_SDA_PIN, SW_SDA_IN			; test for ACK/NACK
	rjmp	iws_skip051
;
; ACK..do next byte
	ldi		r16, SW_I2C_SCL_L_4
	mov		r_i2c_sub_mode, r16
;
	rjmp	ims_exit
;
; NACK..release SDA and go idle.
iws_skip051:
	cbi		SW_SDA_DDR, SW_SDA_OUT			; release SDA on NACK
;
	ldi		r16, SW_I2C_MODE_WSTART			; sit idle until START again
	mov		r_i2c_mode, r16
	rjmp	ims_exit

;
; case SW_I2C_SCL_L_2			Waiting for SCL.L on SLA ACK then stretch clock until data is ready.
iws_skip06:
	cpi		r17, SW_I2C_SCL_L
	breq	iws_skip060
	rjmp	ims_exit
;
; SCL.L edge has completed ACK..set SCL to stretch clock.
iws_skip060:
; OK to release SDA here
	cbi		SW_SDA_DDR, SW_SDA_OUT			; set as input
;;;	sbi		SW_SDA_PORT, SW_SDA_OUT			; enable weak pull-up.
; setting SCL.L to stretch clock.
	sbi		SW_SCL_DDR, SW_SCL_OUT			; set as output
	cbi		SW_SCL_PORT, SW_SCL_OUT
; load counter
	ldi		r16, 8
	mov		r_i2c_bit_cnt, r16
;
	rcall	i2c_sw_load_buff
;
	lsl		r_i2c_buff					; get MSb -> CY
;
	brcc	iws_skip061
	sbi		SW_SDA_PORT, SW_SDA_OUT
	rjmp	iws_skip062
;
iws_skip061:
	cbi		SW_SDA_PORT, SW_SDA_OUT
;
iws_skip062:
; release SCL to end strecth
	cbi		SW_SCL_DDR, SW_SCL_OUT			; set as input
;
	ldi		r16, SW_I2C_SMODE_WDATA			; send other bits on SCL.L
	mov		r_i2c_sub_mode, r16
;
	sbi		SW_SDA_DDR, SW_SDA_OUT			; set as output..Have to do this here
;
	rjmp	ims_exit

;
; case SW_I2C_SCL_L_3					Wait to read data bit on SCL.H
iws_skip07:
	cpi		r17, SW_I2C_SCL_H
	breq	iws_skip070
	rjmp	ims_exit
;
iws_skip070:
	mov		r16, r_i2c_bit_cnt
	cpi		r16, 1
	brne	iws_skip071
;
	cbi		SW_SDA_DDR, SW_SDA_OUT				; set as input allow ACK from Master.
;
iws_skip071:
	ldi		r16, SW_I2C_SMODE_WDATA
	mov		r_i2c_sub_mode, r16
;
	rjmp	ims_exit
;
ims_exit:
	ret

; case SW_I2C_SCL_L_4			Waiting for SCL.L on DATA ACK then stretch clock until data is ready.
iws_skip08:
	cpi		r17, SW_I2C_SCL_L
	breq	iws_skip080
	rjmp	ims_exit
;
; SCL.L edge has completed ACK..set SCL to stretch clock.
iws_skip080:
; setting SCL.L to stretch clock.
	sbi		SW_SCL_DDR, SW_SCL_OUT			; set as output
	cbi		SW_SCL_PORT, SW_SCL_OUT
; load counter
	ldi		r16, 8
	mov		r_i2c_bit_cnt, r16
;
	rcall	i2c_sw_load_buff
;
	lsl		r_i2c_buff						; get MSb
	brcc	iws_skip081
	sbi		SW_SDA_PORT, SW_SDA_OUT
	rjmp	iws_skip082
;
iws_skip081:
	cbi		SW_SDA_PORT, SW_SDA_OUT
;
iws_skip082:
; release SCL to end strecth
	cbi		SW_SCL_DDR, SW_SCL_OUT			; set SCL as input
; output data
	sbi		SW_SDA_DDR, SW_SDA_OUT			; set SDA as output
;
	ldi		r16, SW_I2C_SMODE_WDATA			; send other bits on SCL.L
	mov		r_i2c_sub_mode, r16
;
	rjmp	ims_exit


// Get next byte from FIFO and load r_i2c_buff
i2c_sw_load_buff:
	push	XL
	push	XH
	push	R19
	push	r18								; used by fifo_get() to return status.
;
	ldi		XL, LOW(i2c_buffer_out)
	ldi		XH, HIGH(i2c_buffer_out)
	ldi		r19, I2C_BUFFER_SIZE
	rcall	fifo_get
;;;	ldi		r17, 'y'						; TEST CODE
	mov		r_i2c_buff, r17
; TODO: Should test r18 for valid data of FIFO underflow.
	pop		r18
	pop		r19
	pop		XH
	pop		XL
;
	ret

// Save byte to FIFO from r_i2c_buff
i2c_sw_save_buff:
	push	XL
	push	XH
	push	R19
	push	r18								; used by fifo_get() to return status.
;
	ldi		XL, LOW(i2c_buffer_in)
	ldi		XH, HIGH(i2c_buffer_in)
	ldi		r19, I2C_BUFFER_SIZE
	mov		r17, r_i2c_buff
;
;;;	ldi		r17, 2						; TEST CODE
;
	rcall	fifo_put					; r18 not used
; TODO: Could test r18 for valid data of FIFO overflow. FIFO code would need change also.
	pop		r18
	pop		r19
	pop		XH
	pop		XL
;
	ret

