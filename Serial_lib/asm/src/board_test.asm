/*
 * Board Test Utilities
 *
 * org: 11/19/2014
 * auth: Nels "Chip" Pearson
 *
 * Target: TankBot Board, 20MHz, ATmega164P
 *
 * Dependentcies:
 *   sys_timers.asm
 *
 */

.equ		TB_SERIAL_DELAY	=	100			; N * 10ms


.DSEG
tb_delay:		.BYTE	1
tb_buffer:		.BYTE	4
tb_count:		.BYTE	1


.CSEG
/*
 * Test RS-232 Serial
 *
 */
tb_serial:
	sbis	GPIOR0, DEMO_10MS_TIC		; test 10ms tic
	ret									; EXIT..not set
;
	cbi		GPIOR0, DEMO_10MS_TIC		; clear tic10ms flag set by interrupt
; check delay
	lds		r16, tb_delay
	dec		r16
	sts		tb_delay, r16
	breq	tbs_skip00
	ret									; EXIT..not time
tbs_skip00:
	ldi		r16, TB_SERIAL_DELAY		; 100ms rate
	sts		tb_delay, r16
; Send banner
	call	tb_send_banner_serial
; Send a character
	ldi		r17, 'C'
	call	serial_send_byte
; Send a character
	ldi		r17, ' '
	call	serial_send_byte
; Check for input
	call	serial_recv_byte
	tst		r18
	brne	tbs_exit
	call	serial_send_byte			; echo back
; Send a character
	ldi		r17, ' '
	call	serial_send_byte
;
tbs_exit:
	ret

/*
 * Send Text Banner through Serial Port
 */
tb_send_banner_serial:
	ldi		ZL, LOW(TB_TEXT_BANNER<<1)
	ldi		ZH, HIGH(TB_TEXT_BANNER<<1)
tsbs_loop00:
	lpm		r17, Z+
	tst		r17
	breq	tsbs_exit
	call	serial_send_byte
	rjmp	tsbs_loop00
;
tsbs_exit:
	ret

// NULL terminated text.
TB_TEXT_BANNER:
.db		'R','S','-','2','3','2',' ','C','O','M',0x0A,0x0D,0,0
