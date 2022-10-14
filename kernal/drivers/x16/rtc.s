;----------------------------------------------------------------------
; MCP7940N RTC Driver
;----------------------------------------------------------------------
; (C)2021 Michael Steil, License: 2-clause BSD

.include "regs.inc"

.import i2c_read_byte, i2c_write_byte
.export rtc_get_date_time, rtc_set_date_time

.segment "RTC"

rtc_address = $6f

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
	ldx #rtc_address
	ldy #0
	jsr i2c_read_byte ; 0: seconds
	sta r3L           ; remember seconds register contents
	and #$7f
	jsr bcd_to_bin
	sta r2H

	iny
	jsr i2c_read_byte ; 1: minutes
	jsr bcd_to_bin
	sta r2L

	iny
	jsr i2c_read_byte ; 2: hour (24h mode)
	jsr bcd_to_bin
	sta r1H

	iny
	iny
	jsr i2c_read_byte ; 4: day
	jsr bcd_to_bin
	sta r1L

	iny
	jsr i2c_read_byte ; 5: month
	and #$1f
	jsr bcd_to_bin
	sta r0H

	iny
	jsr i2c_read_byte ; 6: year
	jsr bcd_to_bin
	clc
	adc #100
	sta r0L

	; if seconds have changed since we started
	; reading, read everything again
	ldy #0
	jsr i2c_read_byte
	cmp r3L
	bne rtc_get_date_time

	stz r3L ; jiffies
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
	; stop the clock
	ldx #rtc_address
	ldy #0
    tya
    jsr i2c_write_byte

	ldy #6
	lda r0L
	sec
	sbc #100
	jsr i2c_write_byte_as_bcd ; 6: year

	dey
	lda r0H
	jsr i2c_write_byte_as_bcd ; 5: month

	dey
	lda r1L
	jsr i2c_write_byte_as_bcd ; 4: day

	dey
	lda #$08                  ; enable battery backup, reset week day
	jsr i2c_write_byte_as_bcd ; 3: day of week

	dey
	lda r1H
	jsr i2c_write_byte_as_bcd ; 2: hour (bit 6: 0 -> 24h mode)

	dey
	lda r2L
	jsr i2c_write_byte_as_bcd ; 1: minutes

	dey
	lda r2H
	jsr bin_to_bcd
	ora #$80           ; start the clock
	jmp i2c_write_byte ; 0: seconds

i2c_write_byte_as_bcd:
	jsr bin_to_bcd
	jmp i2c_write_byte

bcd_to_bin:
	phx
	ldx #$ff
	sec
	sed
@1:	inx
	sbc #1
	bcs @1
	cld
	txa
	plx
	rts

bin_to_bcd:
	phy
	tay
	lda #0
	sed
@loop:	cpy #0
	beq @end
	clc
	adc #1
	dey
	bra @loop
@end:	cld
	ply
	rts
