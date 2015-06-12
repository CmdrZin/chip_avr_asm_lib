
/*
 * lcd_hdm16216h_5_lib.s
 *
 * Created: 6/4/2015 9:01:28 PM
 *  Author: Chip
 */ 

#include <avr/io.h>

#define USE_BUSY_FLAG 0				// 0:No..1:Yes

// Local defines
#define LCD_DISPLAY_RS_DDR	(0x17)		//DDRB
#define LCD_DISPLAY_RS_PORT	(0x18)		//PORTB
#define LCD_DISPLAY_RS_PIN	 PB0

#define LCD_DISPLAY_RW_DDR	(0x17)		//DDRB
#define LCD_DISPLAY_RW_PORT	(0x18)		//PORTB
#define LCD_DISPLAY_RW_PIN	 PB1

#define LCD_DISPLAY_E_DDR	(0x17)		//DDRB
#define LCD_DISPLAY_E_PORT	(0x18)		//PORTB
#define LCD_DISPLAY_E_PIN	 PB2

#define LCD_DISPLAY_DATA_DDR	 (0x1A)	//DDRA
#define LCD_DISPLAY_DATA_PORT	 (0x1B)	//PORTA
#define LCD_DISPLAY_DATA_PORTIN	 (0x19)	//PINA

#define LCD_CLEAR_DISPLAY			 0x01	// Write 0x20 to DDRAM and reset AC to 00. [1.64ms]
#define LCD_RETURN_HOME			 0x02	// Reset AC to 00 and return cursor to home. [1.64ms]
#define LCD_SET_ENTRY_MODE			 0x04	// b1: I/D, b0: S Set cursor move and display shift. [40us]
#define  LCD_SE_ID  1						// 0:Decrement..1:Increment
#define  LCD_SE_S  0						// Display shift also..0:No..1:Yes
#define LCD_DISPLAY_ONOFF			 0x08	// b2: Display, b1: Cursor, b0: Cursor position.  [40us]
#define LCD_CURSOR_DISPLAY_SHIFT	 0x10	// b3: Select, b2: R/L. [40us]
#define  LCD_CDS_DISP  2					// Display 0:Off..1:On
#define  LCD_CDS_CUR  1					// Cursor 0:Off..1:On
#define LCD_SET_FUNCTION			 0x20	// b4: Interface, b3: Lines, b2: Font. [40us]
#define  LCD_SF_DL	 4
#define  LCD_SF_N	 3
#define LCD_SET_CGRAM_ADRS			 0x40	// b5:0 CGRAM Address. [40us]
#define LCD_SET_DDRAM_ADRS			 0x80	// b6:0 DDRAM Address. [40us]

#define LCD_SHIFT_CURSOR_LEFT	 0b00000000
#define LCD_SHIFT_CURSOR_RIGHT	 0b00000100
#define LCD_SHIFT_DISPLAY_LEFT	 0b00001000
#define LCD_SHIFT_DISPLAY_RIGHT	 0b00001100

#define LCD_DELAY_40US_COUNT	 40


/*
 * Initialize HDM16216H-5 for 4bit data.
 */
.global lcd_lib_init
lcd_lib_init:
	// Set up IO. Control pins are outputs.
	sbi		LCD_DISPLAY_RS_DDR, LCD_DISPLAY_RS_PIN
	sbi		LCD_DISPLAY_RW_DDR, LCD_DISPLAY_RW_PIN
	sbi		LCD_DISPLAY_E_DDR, LCD_DISPLAY_E_PIN
	// Data IO is set to input or output as needed.

	// wait 50ms after reset.
	ldi		r24, 50
	rcall	lcd_lib_delay_1ms

	// start setup sequence
	// Function set 8 bit
	ldi		r24, LCD_SET_FUNCTION | (1<<LCD_SF_DL)
	rcall	lcd_lib_write_ins_once
	// Wait > 4.1ms
	ldi		r24, 5
	rcall	lcd_lib_delay_1ms

	// Function set 8 bit
	ldi		r24, LCD_SET_FUNCTION | (1<<LCD_SF_DL)
	rcall	lcd_lib_write_ins_once
	// wait > 100us
	rcall	lcd_lib_delay_40us
	rcall	lcd_lib_delay_40us
	rcall	lcd_lib_delay_40us

	// Function set 8 bit
	ldi		r24, LCD_SET_FUNCTION | (1<<LCD_SF_DL)
	rcall	lcd_lib_write_ins_once
	// Wait instruction time since no BUSY check yet.
	rcall	lcd_lib_delay_40us

	// Function set 4 bit
	ldi		r24, LCD_SET_FUNCTION | (0<<LCD_SF_DL)
	rcall	lcd_lib_write_ins_once
	// Wait instruction time since no BUSY check yet.
	rcall	lcd_lib_delay_40us

	// Function set 2 lines w/ 5x7 font
	ldi		r24, LCD_SET_FUNCTION | (0<<LCD_SF_DL) | (1<<LCD_SF_N)
	rcall	lcd_lib_write_ins_nochk
	// Wait instruction time since no BUSY check yet.
	rcall	lcd_lib_delay_40us

	// Display OFF
	ldi		r24, LCD_DISPLAY_ONOFF
	rcall	lcd_lib_write_ins_nochk
	// Wait instruction time since no BUSY check yet.
	rcall	lcd_lib_delay_40us

	// Display Clear
	ldi		r24, LCD_CLEAR_DISPLAY
	rcall	lcd_lib_write_ins_nochk
	// Wait > 1.64ms
	ldi		r24, 2
	rcall	lcd_lib_delay_1ms

	// Entry Mode set, inc and no shift
	ldi		r24, LCD_SET_ENTRY_MODE | (1<<LCD_SE_ID) | (0<<LCD_SE_S)
	rcall	lcd_lib_write_ins_nochk
	// Wait instruction time since no BUSY check yet.
	rcall	lcd_lib_delay_40us
	// END of Software Initialization
	/* Display Test Banner */
	// Display ON, Cursor ON
	ldi		r24, LCD_DISPLAY_ONOFF | (1<<LCD_CDS_DISP) | (1<<LCD_CDS_CUR)
#if USE_BUSY_FLAG
	rcall	lcd_lib_write_ins_chk
#else
	rcall	lcd_lib_write_ins_nochk
	// Wait instruction time since no BUSY check yet.
	rcall	lcd_lib_delay_40us
#endif
	// Set DD RAM Adrs
	ldi		r24, 0x08
	rcall	lcd_lib_set_ddram

	// Write Text
	ldi		r24, 'H'
	rcall	lcd_lib_ram_write
#if	USE_BUSY_FLAG
	rcall	lcd_lib_check_busy
#else
	// Wait instruction time since no BUSY check yet.
	rcall	lcd_lib_delay_40us
	rcall	lcd_lib_delay_40us
#endif

	// Write Text
	ldi		r24, 'I'
	rcall	lcd_lib_ram_write
#if	USE_BUSY_FLAG
	rcall	lcd_lib_check_busy
#else
	// Wait instruction time since no BUSY check yet.
	rcall	lcd_lib_delay_40us
	rcall	lcd_lib_delay_40us
#endif

	// Set DD RAM Adrs
	ldi		r24, 0x0B
	rcall	lcd_lib_set_ddram

	// Write Text
	ldi		r24, 'Y'
	rcall	lcd_lib_ram_write
#if	USE_BUSY_FLAG
	rcall	lcd_lib_check_busy
#else
	// Wait instruction time since no BUSY check yet.
	rcall	lcd_lib_delay_40us
	rcall	lcd_lib_delay_40us
#endif

	ret

/*
 * r24 = DD RAM address 00-7F
 * C callable so only r19:18, r21:20, r23:22, r25:24 X, & Z are free to use.
 */
.global lcd_lib_set_ddram
lcd_lib_set_ddram:
	andi	r24, 0x3F					// mask out data
	ori		r24, LCD_SET_DDRAM_ADRS
#if USE_BUSY_FLAG
	rcall	lcd_lib_write_ins_chk
#else
	rcall	lcd_lib_write_ins_nochk
	// Wait instruction time since no BUSY check yet.
	rcall	lcd_lib_delay_40us
#endif
	ret

/* These delays are used instead of assuming a timer is available. */
.global lcd_lib_delay_40us
lcd_lib_delay_40us:
	ldi		r24, LCD_DELAY_40US_COUNT
lld4_loop0:
	// Adjust for 1us delay at 8MHz. Could be based on a CPU_CLOCK define.
	nop
	nop
	nop
	nop
	nop
	dec		r24
	brne	lld4_loop0
	ret

/*
 * r24 = msDelay
 * C callable so only r19:18, r21:20, r23:22, r25:24 X, & Z are free to use.
 */
.global lcd_lib_delay_1ms
lcd_lib_delay_1ms:
	mov		r18, r24					// save delay
lld1_loop0:
	ldi		r19, 25
lld1_loop1:
	rcall	lcd_lib_delay_40us
	dec		r19
	brne	lld1_loop1
	dec		r18
	brne	lld1_loop0	
	ret

.global lcd_lib_ram_write
/*
 * set up address before calling.
 * r24 = data
 */
lcd_lib_ram_write:
	sbi		LCD_DISPLAY_RS_PORT, LCD_DISPLAY_RS_PIN		// RS=1
	cbi		LCD_DISPLAY_RW_PORT, LCD_DISPLAY_RW_PIN		// RW=0
	mov		r18, r24				// save data
	// output upper bits
	swap	r24
	rcall	lcd_lib_raw_write
#if	USE_BUSY_FLAG
	rcall	lcd_lib_check_busy
#else
	// Wait instruction time since no BUSY check yet.
	rcall	lcd_lib_delay_40us
	rcall	lcd_lib_delay_40us
#endif
	// output lower bits
	mov		r24, r18
	rcall	lcd_lib_raw_write
#if	USE_BUSY_FLAG
	rcall	lcd_lib_check_busy
#else
	// Wait instruction time since no BUSY check yet.
	rcall	lcd_lib_delay_40us
	rcall	lcd_lib_delay_40us
#endif
;
	ret

.global lcd_lib_ram_read
lcd_lib_ram_read:
	sbi		LCD_DISPLAY_RS_PORT, LCD_DISPLAY_RS_PIN		// RS=1
	sbi		LCD_DISPLAY_RW_PORT, LCD_DISPLAY_RW_PIN		// RW=1
	rcall	lcd_lib_raw_read								// r24 = data
	push	r24											// save
	rcall	lcd_lib_raw_read								// r24 = data
	andi	r24, 0x0F
	pop		r25
	swap	r25
	andi	r25, 0xF0
	or		r24, r25
;
	ret


.global lcd_lib_write_ins_chk
.global lcd_Lib_write_ins_nochk
.global lcd_lib_write_ins_once
/*
 * r24 = data
 */
lcd_lib_write_ins_chk:
	push	r24							// save input data
	rcall	lcd_lib_check_busy			// Blocking call if BUSY.
	pop		r24
// This take an 8bit command and outputs the upper 4bits then the lower 4bits.
lcd_lib_write_ins_nochk:
	cbi		LCD_DISPLAY_RS_PORT, LCD_DISPLAY_RS_PIN		// RS=0
	cbi		LCD_DISPLAY_RW_PORT, LCD_DISPLAY_RW_PIN		// RW=0
	// output upper bits
	push	r24
	swap	r24
	rcall	lcd_lib_raw_write
	// output lower bits
	pop		r24
	rcall	lcd_lib_raw_write
;
	ret
;
lcd_lib_write_ins_once:
	// Set these when called directly also.
	cbi		LCD_DISPLAY_RS_PORT, LCD_DISPLAY_RS_PIN		// RS=0
	cbi		LCD_DISPLAY_RW_PORT, LCD_DISPLAY_RW_PIN		// RW=0
	swap	r24											// upper bits used for 4 bit io
	rcall	lcd_lib_raw_write
	ret

.global lcd_lib_check_busy
/* BLOCKING call if BUSY is set. */
lcd_lib_check_busy:
llbc_loop0:
	cbi		LCD_DISPLAY_RS_PORT, LCD_DISPLAY_RS_PIN		// RS=0
	sbi		LCD_DISPLAY_RW_PORT, LCD_DISPLAY_RW_PIN		// RW=1
	rcall	lcd_lib_raw_read			// r24 = data
	andi	r24, 0x80				// BUSY bit
	brne	llbc_loop0
;
	ret

.global lcd_lib_raw_read
/*
 * Only used for BUSY Flag check.
 * Set RS and RW before calling.
 */
lcd_lib_raw_read:
	// Set up data
	in		r24, LCD_DISPLAY_DATA_DDR
	andi	r24, 0xF0
	out		LCD_DISPLAY_DATA_DDR, r24					// set as input
	// Toggle E
	sbi		LCD_DISPLAY_E_PORT, LCD_DISPLAY_E_PIN		// set E=1. Min 360ns width. 4 clocks @ 8MHz.
	nop
	nop
	nop
	nop
	nop
	nop
	in		r24, LCD_DISPLAY_DATA_PORTIN				// read
	cbi		LCD_DISPLAY_E_PORT, LCD_DISPLAY_E_PIN		// clear E=0.
;
	ret

.global lcd_lib_raw_write
/*
 * Set RS and RW before calling.
 * Diagram shows 360ns data setup max after rising edge of E.
 * Just setup data BEFORE raising E.
 * Hold time after E falls is 10ns. One nop will do.
 * ASSUMES lower four bits are data lines.
 * r24 = data
 */
lcd_lib_raw_write:
	// Set up data
	in		r25, LCD_DISPLAY_DATA_DDR
	ori		r25, 0x0F
	out		LCD_DISPLAY_DATA_DDR, r25					// set as output
	in		r25, LCD_DISPLAY_DATA_PORT
	andi	r25, 0xF0									// clear bits first
	andi	r24, 0x0F
	or		r24, r25									// then OR the data
	out		LCD_DISPLAY_DATA_PORT, r24
	nop
	nop
	// Toggle E
	sbi		LCD_DISPLAY_E_PORT, LCD_DISPLAY_E_PIN		// set E=1. Min 240ns width. 2 clocks @ 8MHz.
	nop
	nop
	nop
	nop
	cbi		LCD_DISPLAY_E_PORT, LCD_DISPLAY_E_PIN		// clear E=0.
;
	ret
