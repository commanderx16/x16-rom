;----------------------------------------------------------------------
; MCP7940N RTC Driver
;----------------------------------------------------------------------
; (C)2021 Michael Steil, License: 2-clause BSD

.export rtc_get_date_time, rtc_set_date_time

.include "io.inc"
.include "regs.inc"

.import _i2cStart, _i2cStop, _i2cAck, _i2cNack, _i2cWrite, _i2cRead

.import i2c_read_byte, i2c_write_byte

.segment "CLOCK"

rtc_address = $6f

rtc_init:
	ldx #rtc_address
	ldy #0
	jsr i2c_read_byte
	ora #$80
	jmp i2c_write_byte

;---------------------------------------------------------------
; rtc_set_date_time
;
; Function:  Get the current date and time
;
; Return:    r0L  year
;            r0H  month
;            r1L  day
;            r1H  hours
;            r2L  minutes
;            r2H  seconds
;            r3L  jiffies
;---------------------------------------------------------------
rtc_get_date_time:
	jsr rtc_init

	stz r3L ; jiffies

	ldx #rtc_address
	ldy #0
	jsr i2c_read_byte ; 0: seconds
	sta r2H

	iny
	jsr i2c_read_byte ; 1: minutes
	sta r2L

	iny
	jsr i2c_read_byte ; 2: hour
	sta r1H

	iny
	iny
	jsr i2c_read_byte ; 4: day
	sta r1L

	iny
	jsr i2c_read_byte ; 5: month
	sta r0H

	iny
	jsr i2c_read_byte ; 6: year
	sta r0L
	rts

;---------------------------------------------------------------
; rtc_set_date_time
;
; Function:  Set the current date and time
;
; Pass:      r0L  year
;            r0H  month
;            r1L  day
;            r1H  hours
;            r2L  minutes
;            r2H  seconds
;            r3L  jiffies
;---------------------------------------------------------------
rtc_set_date_time:
	rts
