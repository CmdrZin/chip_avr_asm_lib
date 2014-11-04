/*
 * FIFO Library
 *
 * org: 11/03/2014
 * auth: Nels "Chip" Pearson
 *
 * Target: ATmega164P
 *
 * Basic utilities for FIFO support.
 *
 */

.equ	SER_BUFF_SIZE	= 32


.DSEG
// Common struct used by FIFO utilities.
ser_in_buff:		.BYTE	SER_BUFF_SIZE
ser_in_fifo_head:	.BYTE	1
ser_in_fifo_tail:	.BYTE	1

ser_out_buff:		.BYTE	SER_BUFF_SIZE
ser_out_fifo_head:	.BYTE	1
ser_out_fifo_tail:	.BYTE	1


.CSEG
/* **** Utilites **** */

/*
 * Get one byte from FIFO
 * input reg:	X		*buffer
 *				r19		buffer size
 *
 * output reg:	r17		Data
 *				R18		Data valid..0:valid..1:no data
 *
 * head - in index to FIFO = *(buffer+SIZE)
 * tail - out index to FIFO = *(buffer+SIZE+1)
 *
 * NOTE: Called from INTR service routine. SAVE regs.
 */
fifo_get:
	push	r16
	push	r19
	push	XL
	push	XH
	push	YL
	push	YH
	push	ZL
	push	ZH
// setup FIFO controls
	clr		YH						; offset to head index
	mov		YL, r19
	add		YL, XL
	adc		YH, XH
;
	clr		ZH						; offset to tail index
	mov		ZL, r19
	inc		ZL
	add		ZL, XL
	adc		ZH, XH
;	
	ld		r16, Y					; head
	ld		r18, Z					; tail
	cp		r16, r18				; test for empty
	brne	fg001					; skip if data	
	ldi		r18, 1					; no data
	rjmp	fg_exit					; EXIT
;
fg001:
// 16 bit add..X + tail
	add		XL, r18
	clr		r16
	adc		XH, r16
	ld		r17, X					; get data
// Update i2c_tail
	inc		r18
// check for wrap around
	cp		r18, r19
	brne	fg002
// at end
	clr		r18
fg002:
	st		Z, r18
	clr		r18
;
fg_exit:
	pop		ZH
	pop		ZL
	pop		YH
	pop		YL
	pop		XH
	pop		XL
	pop		r19
	pop		r16
	ret

/*
 * Put one byte into FIFO
 *
 * NOTE: Overflow tested. If FULL, don't store.
 * TODO: Set or return error OV=1???
 *
 * input reg:	X			*buffer
 *				r19			buffer size
 *
 * output reg:	none
 *
 * head - in index to FIFO = *(buffer+SIZE)
 * tail - out index to FIFO = *(buffer+SIZE+1)
 *
 * NOTE: Called from INTR service routine. SAVE regs.
 */
fifo_put:
	push	r16
	push	r17
	push	r18
	push	r19
	push	XL
	push	XH
	push	YL
	push	YH
	push	ZL
	push	ZH
// setup FIFO controls
	clr		YH						; offset to head index
	mov		YL, r19
	add		YL, XL
	adc		YH, XH
;
	clr		ZH						; offset to tail index
	mov		ZL, r19
	inc		ZL
	add		ZL, XL
	adc		ZH, XH
;	
	ld		r16, Y					; head
	inc		r16						; test end
	ld		r18, Z					; tail
	cp		r16, r18				; test for full
	brne	fp001					; skip if data
; error OV
	rjmp	fp_exit
;
fp001:
	dec		r16
	add		XL, r16
	clr		r18
	adc		XH, r18
	st		X, r17					; put data
// Update i2c_head
	inc		r16
// check for wrap around
	cp		r16, r19
	brne	fp002
// at end
	clr		r16						; reset
fp002:
	st		Y, r16
;
fp_exit:
	pop		ZH
	pop		ZL
	pop		YH
	pop		YL
	pop		XH
	pop		XL
	pop		r19
	pop		r18
	pop		r17
	pop		r16
	ret
