
/*
 * flash_table.s
 *
 * Created: 6/27/2015 7:02:52 PM
 *  Author: Chip
 */ 

 #include <avr/io.h>

.global flash_get_dev_access_id
/*
 * r25:r24 = index (H,L)
 * dev_access_table has 6 bytes per entry. (see sysdefs.h DEV_ACCESS_ENTRY)
 * returns r25:24 = dev_access_table[index].id
 * Z = r31:30
 */
 flash_get_dev_access_id:
	; multiply index by 6
	mov		r18, r24
	add		r24, r24			; double
	add		r24, r18			; x3
	add		r24, r24			; x6
	; Z = table
	ldi		r31, hi8((dev_access_table))
	ldi		r30, lo8((dev_access_table))
	; add index
	add		r30, r24
	adc		r31, r1					; r1 always 0
	; get id
	lpm		r24, Z
	mov		r25, r1
	;
	ret

.global flash_get_dev_function_table
/*
 * r25:r24 = index
 * dev_access_table has 6 bytes per entry. (see sysdefs.h DEV_ACCESS_ENTRY)
 * returns r25:24 = dev_access_table[index].cmd_table
 */
 flash_get_dev_function_table:
	; multiply index by 6
	mov		r18, r24
	add		r24, r24			; double
	add		r24, r18			; x3
	add		r24, r24			; x6
	; Z = table
	ldi		r31, hi8((dev_access_table))
	ldi		r30, lo8((dev_access_table))
	; add index
	add		r30, r24
	adc		r31, r1					; r1 always 0
	; add offset to cmd table
	adiw	r30, 2
	; get cmd table
	lpm		r24, Z+
	lpm		r25, Z
	;
	ret

.global flash_get_dev_size_table
/*
 * r25:r24 = index
 * dev_access_table has 6 bytes per entry. (see sysdefs.h DEV_ACCESS_ENTRY)
 * returns r25:24 = dev_access_table[index].size_table
 */
 flash_get_dev_size_table:
	; multiply index by 6
	mov		r18, r24
	add		r24, r24			; double
	add		r24, r18			; x3
	add		r24, r24			; x6
	; Z = table
	ldi		r31, hi8((dev_access_table))
	ldi		r30, lo8((dev_access_table))
	; add index
	add		r30, r24
	adc		r31, r1					; r1 always 0
	; add offset to cmd table
	adiw	r30, 4
	; get cmd table
	lpm		r24, Z+
	lpm		r25, Z
	;
	ret


.global flash_get_size_cmd
.global flash_get_access_cmd
/*
 * r25:24	= index
 * r23:22	= table
 * table has 4 bytes per entry. A Key and a Value (see sysdefs.h DEV_COMMAND_SIZE or DEV_FUNCTION_ENTRY)
 */
 flash_get_size_cmd:
 flash_get_access_cmd:
	; multiply index by 4
	add		r24, r24			; double
	add		r24, r24			; x4
	; Z = table
	mov		r30, r22
	mov		r31, r23
	; add index
	add		r30, r24
	adc		r31, r1					; r1 always 0
	; get key
	lpm		r24, Z+
	lpm		r25, Z
	;
	ret

.global flash_get_access_func
/*
 * r25:24	= index
 * r23:22	= table
 * table has 4 bytes per entry. A Key and a Value (see sysdefs.h DEV_COMMAND_SIZE or DEV_FUNCTION_ENTRY)
 */
 flash_get_access_func:
	; multiply index by 4
	add		r24, r24			; double
	add		r24, r24			; x4
	; Z = table
	mov		r30, r22
	mov		r31, r23
	; add index
	add		r30, r24
	adc		r31, r1					; r1 always 0
	; add offset to value
	adiw	r30, 2
	; get key
	lpm		r24, Z+
	lpm		r25, Z
	;
	ret

.global flash_get_size_nbytes
/*
 * r25:24	= index
 * r23:22	= table
 * table has 4 bytes per entry. A Key and a Value (see sysdefs.h DEV_COMMAND_SIZE or DEV_FUNCTION_ENTRY)
 */
 flash_get_size_nbytes:
	; multiply index by 4
	add		r24, r24			; double
	add		r24, r24			; x4
	; Z = table
	mov		r30, r22
	mov		r31, r23
	; add index
	add		r30, r24
	adc		r31, r1					; r1 always 0
	; add offset to value
	adiw	r30, 2
	; get key
	lpm		r24, Z+
	mov		r25, r1
	;
	ret
