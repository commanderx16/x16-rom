;----------------------------------------------------------------------
; MCP7940N RTC Driver
;----------------------------------------------------------------------
; (C)2021 Michael Steil, License: 2-clause BSD

.export rtc_get_date_time, rtc_set_date_time

.include "io.inc"
.include "regs.inc"

.import _i2cStart, _i2cStop, _i2cAck, _i2cNack, _i2cWrite, _i2cRead

.segment "CLOCK"

rtc_address = $6f * 2

rtc_read_byte:
	phx
	jsr _i2cStart
	lda #rtc_address
	jsr _i2cWrite
	pla
	jsr _i2cWrite
	jsr _i2cStop
	jsr _i2cStart
	lda #rtc_address + 1
	jsr _i2cWrite
	jsr _i2cRead
	pha
	jsr _i2cNack
	pla
	rts

rtc_write_byte:
	pha
	phx
	jsr _i2cStart
	lda #rtc_address
	jsr _i2cWrite
	pla
	jsr _i2cWrite
	pla
	jsr _i2cWrite
	jmp _i2cStop


rtc_init:
	ldx #0
	jsr rtc_read_byte
	ora #$80
	ldx #0
	jmp rtc_write_byte


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

	jsr _i2cStart
	lda #rtc_address
	jsr _i2cWrite
	lda #0
	jsr _i2cWrite
	jsr _i2cStop
	jsr _i2cStart
	lda #rtc_address + 1
	jsr _i2cWrite

	jsr _i2cRead ; 0: seconds
	sta r2H
	jsr _i2cAck

	jsr _i2cRead ; 1: minutes
	sta r2L
	jsr _i2cAck

	jsr _i2cRead ; 2: hour
	sta r1H
	jsr _i2cAck

	jsr _i2cRead ; 3: day of week
	; ignore
	jsr _i2cAck

	jsr _i2cRead ; 4: day
	sta r1L
	jsr _i2cAck

	jsr _i2cRead ; 5: month
	sta r0H
	jsr _i2cAck

	jsr _i2cRead ; 6: year
	sta r0L
	jsr _i2cNack
	jmp _i2cStop

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
