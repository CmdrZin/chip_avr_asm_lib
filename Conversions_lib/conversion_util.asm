;
; Util_Conversions.asm
;
; org: 10/21/2014
; Author : Nels "Chip" Pearson (aka CmdrZin)
; revised: 12/13/2020 1:11:08 PM
;
; Target: Any AVR
;
; Usage:
;	.include conversion_util.asm
;
; This file is for use by Atmel Studio 7 ASM projects.
; Note the register usage for conflicts with your code.
;
; For C/C++ projects, use Util_Conversions_C.s, .h files.
;
; These functions are for converting data formats
;   bin2bcd_10_4		- Convert 10 bit value in R18:R17 to BCD in RAM pointed to by X.
; 
;

.DSEG
con_util_bcd_buff:		.BYTE	2

.CSEG
/*
 * bin2bcd_10_4()
 *
 * Convert 10 bits to 4 digit BCD
 *
 * input:	R18[7:0] = b9:2		R17[7:6] = b1:0
 *
 * output:	X -> BCD..LSB
 *
 * Register Use: R16:R22, X(R27:R26)
 * RAM use: 2 bytes.
 * Designed for ADC use with ADCH(R18), ADCL(R17) and ADLAR=1.
 *
 * Algorythm
 *   Test if any nibble of >=5 is to be shifted, then add 3 to nibble.
 *
 */
bin2bcd_10_4:
; presets
	ldi		R19, 0x03
	ldi		R20, 0x30
	ldi		R21, 7		; shift count
; shift 2 bits
	lsl		R17			; LSBs
	rol		R18
	rol		R16			; shift to test reg
	lsl		R17			; LSBs
	rol		R18
	rol		R16			; shift to test reg
	sts		con_util_bcd_buff, R16
; algorythm
bb10_4_loop00:
; Shift into buffer
	lsl		R17			; LSBs
	rol		R18
bb10_4_loop01:
	lds		R16, con_util_bcd_buff
	rol		R16
	sts		con_util_bcd_buff, R16
	lds		R16, con_util_bcd_buff+1
	rol		R16
	sts		con_util_bcd_buff+1, R16
;
	ldi		XL, low(con_util_bcd_buff)
	ldi		XH, high(con_util_bcd_buff)
	ldi		R22, 2		; buffer size
bb10_4_loop02:
; test >=0x05
	ld		R16, X
	push	R16
	andi	R16, 0x0F
	cpi		R16, 0x05
	brlo	bb10_4_skip00		; unsigned check
	pop		R16
	add		R16, R19			; add 0x03
	rjmp	bb10_4_skip01
;
bb10_4_skip00:
	pop		R16
bb10_4_skip01:
; test >=0x50
	push	R16
	andi	R16, 0xF0
	cpi		R16, 0x50
	brlo	bb10_4_skip03		; unsigned check
	pop		R16
	add		R16, R20			; add 0x30
	rjmp	bb10_4_skip04
;
bb10_4_skip03:
	pop		R16
bb10_4_skip04:
	st		X+, R16
	dec		R22
	brne	bb10_4_loop02		; test next buffer byte
;
	dec		R21
	brne	bb10_4_loop00		; do next bit
; do last shift
; Shift into buffer
	lsl		R17			; LSBs
	rol		R18
bb10_4_loop03:
	lds		R16, con_util_bcd_buff
	rol		R16			; shift to test reg
	sts		con_util_bcd_buff, R16
	lds		R16, con_util_bcd_buff+1
	rol		R16			; shift to test reg
	sts		con_util_bcd_buff+1, R16
; restore X
	ldi		XL, low(con_util_bcd_buff)
	ldi		XH, high(con_util_bcd_buff)
;
	ret
