;----------------------------------------------------------------------
; MC146818/DS128X RTC Driver
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.export rtc_get_date_time, rtc_set_date_time

.include "io.inc"
.include "regs.inc"

.segment "CLOCK"

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
	lda #$b
	sta rtc_a
	lda #%10000110 ; stop update; binary; 24h
	sta rtc_d
	ldx #0
	stx r3L; jiffies (unsupported, always 0)
	stx rtc_a
	lda rtc_d
	sta r2H ; seconds
	ldx #2
	stx rtc_a
	lda rtc_d
	sta r2L ; minutes
	ldx #4
	stx rtc_a
	lda rtc_d
	sta r1H ; hours
	ldx #7
	stx rtc_a
	lda rtc_d
	sta r1L ; day
	inx ; 8
	stx rtc_a
	lda rtc_d
	sta r0H ; month
	inx ; 9
	stx rtc_a
	lda rtc_d
	clc
	adc #100 ; convert 2000-based to 1900-based
	sta r0L ; year
	lda #$b
	sta rtc_a
	lda #%110 ; continue update; binary; 24h
	sta rtc_d
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
	lda #$b
	sta rtc_a
	lda #%10000110 ; stop update; binary; 24h
	sta rtc_d
	ldx #0
	stx rtc_a
	lda r2H ; seconds
	sta rtc_d
	ldx #2
	stx rtc_a
	lda r2L ; minutes
	sta rtc_d
	ldx #4
	stx rtc_a
	lda r1H ; hours
	sta rtc_d
	ldx #7
	stx rtc_a
	lda r1L ; day
	sta rtc_d
	inx ; 8
	stx rtc_a
	lda r0H ; month
	sta rtc_d
	inx ; 9
	stx rtc_a
	lda r0L ; year
	sec
	sbc #100 ; convert 1900-based to 2000-based
	sta rtc_d
	lda #$b
	sta rtc_a
	lda #%110 ; continue update; binary; 24h
	sta rtc_d
	rts
