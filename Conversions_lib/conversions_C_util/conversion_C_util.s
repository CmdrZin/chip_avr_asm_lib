/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2016 Nels D. "Chip" Pearson (aka CmdrZin)
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 *
 * conversion_C_util.s
 *
 * Created: 12/13/2020	0.01	ndp
 * Author: Nels "Chip" Pearson (aka CmdrZin)
 *
 * These functions are for converting data formats
 *   bin2bcd_10_4		- Convert 10 bit value in uint16_t to BCD in a RAM buffer[2] pointed to by uint8_t*.
 *						- Upper 6 bits of input will be cleared to zero. Max value 1023.
 *						- A buffer is used for the output because this function is usually followed by a serial 
 *							or other communication output routine.
 *
 *   bin2bcd_13_4		- Convert 13 bit value in uint16_t to BCD in a RAM buffer[2] pointed to by uint8_t*.
 *						- Upper 3 bits of input will be cleared to zero. Max value 8191.
 *						- A buffer is used for the output because this function is usually followed by a serial 
 *							or other communication output routine.
 *
 * NOTE: Save and restore if used: r0, r1=0, r2-r17, Y(r29,r28)
 *		 Freely use: r18-r25, X(r27,r26), Z(r31,r30)
 */ 

 #include <avr/io.h>

.global bin2bcd_10_4
/* void bin2bcd_10_4(uint16_t bin10Val, uint8_t* bcdBuffer);
 *
 * r25:r24 = input (b9:8,b7:0)
 * r23:r22 = buffer pointer for output of two bytes. buffer[2]
 *
 * Algorythm
 *   Test if any nibble of >=5 is to be shifted, then add 3 to nibble.
 *
 * This function is C safe with regards to register use.
 */
bin2bcd_10_4:
; save buffer pointer into X
	mov		r27, r23
	mov		r26, r22
; prepare input by masking out lower 10 bits.
	andi	R25, 0x03;
; shift input by 6 to left justify
	ldi		R21, 6		; shift count
bb10_4_loopI:
	lsl		R24			; LSB
	rol		R25
	dec		R21
	brne	bb10_4_loopI	; do next bit
; presets
	ldi		R23, 0		; zero test register
	ldi		R19, 0x03	; Lower nibble adj value
	ldi		R20, 0x30	; Upper nibble adj value
	ldi		R21, 7		; shift count
; shift 2 bits since 2 bits can not be >= 5.
bb10_alt:
	lsl		R24			; LSBs
	rol		R25
	rol		R23			; shift into test reg
	lsl		R24			; LSBs
	rol		R25
	rol		R23			; shift to test reg
	st		X, R23
; save X base
	mov		R31, R27
	mov		R30, R26
; zero out buffer[1]..R22 not used yet.
	ld		R22, Z+		; inc Z
	st		Z, R01		; zero buffer[1]
	ld		R22, -Z		; restore Z
; algorythm
bb10_4_loop00:
; restore X base
	mov		R27, R31
	mov		R26, R30
; Shift into buffer
	lsl		R24			; LSBs
	rol		R25
bb10_4_loop01:
	ld		R23, X
	rol		R23
	st		X+, R23
	ld		R23, X
	rol		R23
	st		X, R23
; restore X base
	mov		R27, R31
	mov		R26, R30
;
	ldi		R22, 2		; buffer size
bb10_4_loop02:
; test >=0x05
	ld		R23, X
	push	R23
	andi	R23, 0x0F
	cpi		R23, 0x05
	brlo	bb10_4_skip00		; unsigned check
	pop		R23
	add		R23, R19			; add 0x03
	rjmp	bb10_4_skip01
;
bb10_4_skip00:
	pop		R23
bb10_4_skip01:
; test >=0x50
	push	R23
	andi	R23, 0xF0
	cpi		R23, 0x50
	brlo	bb10_4_skip03		; unsigned check
	pop		R23
	add		R23, R20			; add 0x30
	rjmp	bb10_4_skip04
;
bb10_4_skip03:
	pop		R23
bb10_4_skip04:
	st		X+, R23
	dec		R22
	brne	bb10_4_loop02		; test next buffer byte
;
	dec		R21
	brne	bb10_4_loop00		; do next bit
; do last shift
; Shift into buffer
	lsl		R24			; LSBs
	rol		R25
bb10_4_loop03:
	ld		R23, Z
	rol		R23					; shift test reg
	st		Z+, R23
	ld		R23, Z
	rol		R23					; shift test reg
	st		Z, R23
;
	ret

.global bin2bcd_13_4
/* void bin2bcd_13_4(uint16_t bin13Val, uint8_t* bcdBuffer);
 *
 * r25:r24 = input (b12:8,b7:0)
 * r23:r22 = buffer pointer for output of two bytes. buffer[2]
 *
 * Algorythm
 *   Test if any nibble of >=5 is to be shifted, then add 3 to nibble.
 *
 * This function is C safe with regards to register use.
 */
bin2bcd_13_4:
; save buffer pointer into X
	mov		r27, r23
	mov		r26, r22
; prepare input by masking out lower 13 bits.
	andi	R25, 0x1F;
; shift input by 3 to left justify
	ldi		R21, 3		; shift count
bb13_4_loopI:
	lsl		R24			; LSB
	rol		R25
	dec		R21
	brne	bb13_4_loopI	; do next bit
; presets
	ldi		R23, 0		; zero test register
	ldi		R19, 0x03	; Lower nibble adj value
	ldi		R20, 0x30	; Upper nibble adj value
	ldi		R21, 10		; shift count
; presets use bin2bcd_10_4 code after prep
	rjmp	bb10_alt

	.global bin2bcd_16_5
/* void bin2bcd_16_5(uint16_t bin10Val, uint8_t* bcdBuffer);
 *
 * r25:r24 = input (b15:8,b7:0)
 * r23:r22 = buffer pointer for output of three bytes. buffer[3]
 *
 * Algorythm
 *   Test if any nibble of >=5 is to be shifted, then add 3 to nibble.
 *
 * This function is C safe with regards to register use.
 */
bin2bcd_16_5:
; save buffer pointer into X
	mov		r27, r23
	mov		r26, r22
; presets
	ldi		R23, 0		; zero test register
	ldi		R19, 0x03	; Lower nibble adj value
	ldi		R20, 0x30	; Upper nibble adj value
	ldi		R21, 13		; shift count 2+13+1
; shift 2 bits since 2 bits can not be >= 5.
	lsl		R24			; LSBs
	rol		R25
	rol		R23			; shift into test reg
	lsl		R24			; LSBs
	rol		R25
	rol		R23			; shift to test reg
	st		X, R23
; save X base
	mov		R31, R27
	mov		R30, R26
; zero out buffer[1]..R22 not used yet.
	ld		R22, Z+		; inc Z
	st		Z+, R01		; zero buffer[1]
	st		Z, R01		; zero buffer[2]
	ld		R22, -Z		; restore Z
	ld		R22, -Z		; restore Z
; algorythm
bb16_5_loop00:
; restore X base
	mov		R27, R31
	mov		R26, R30
; Shift into buffer
	lsl		R24			; LSBs
	rol		R25
bb16_5_loop01:
	ld		R23, X
	rol		R23
	st		X+, R23
	ld		R23, X
	rol		R23
	st		X+, R23
	ld		R23, X
	rol		R23
	st		X, R23
; restore X base
	mov		R27, R31
	mov		R26, R30
;
	ldi		R22, 3		; buffer size
bb16_5_loop02:
; test >=0x05
	ld		R23, X
	push	R23
	andi	R23, 0x0F
	cpi		R23, 0x05
	brlo	bb16_5_skip00		; unsigned check
	pop		R23
	add		R23, R19			; add 0x03
	rjmp	bb16_5_skip01
;
bb16_5_skip00:
	pop		R23
bb16_5_skip01:
; test >=0x50
	push	R23
	andi	R23, 0xF0
	cpi		R23, 0x50
	brlo	bb16_5_skip03		; unsigned check
	pop		R23
	add		R23, R20			; add 0x30
	rjmp	bb16_5_skip04
;
bb16_5_skip03:
	pop		R23
bb16_5_skip04:
	st		X+, R23
;
	dec		R22
	brne	bb16_5_loop02		; test next buffer byte
;
	dec		R21
	brne	bb16_5_loop00		; do next bit
; do last shift
; Shift into buffer
	lsl		R24			; LSBs
	rol		R25
bb16_5_loop03:
	ld		R23, Z
	rol		R23					; shift test reg
	st		Z+, R23
	ld		R23, Z
	rol		R23					; shift test reg
	st		Z+, R23
	ld		R23, Z
	rol		R23					; shift test reg
	st		Z, R23
;
	ret
