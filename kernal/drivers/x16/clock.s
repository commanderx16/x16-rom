;----------------------------------------------------------------------
; X16 Clock Driver
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.include "regs.inc"
.include "banks.inc"
.include "io.inc"

.import softclock_timer_update, softclock_timer_get, softclock_timer_set
.import rtc_get_date_time, rtc_set_date_time

; KERNAL API
.export clock_update
.export clock_get_timer
.export clock_set_timer
.export clock_get_date_time
.export clock_set_date_time

.segment "CLOCK"

;---------------------------------------------------------------
; clock_update
;
; Function:  Update timer, date and time. Needs to be called
;            every 1/60 seconds on average for accurate state.
;
; Note:     The original symbol is UDTIM.
;---------------------------------------------------------------
clock_update = softclock_timer_update

;---------------------------------------------------------------
; clock_get_timer
;
; Function:  Return 24 bit 60 Hz timer
;
; Return:    a    bits 0-7
;            x    bits 8-15
;            y    bits 16-23
;
; Note:     The original symbol is RDTIM.
;---------------------------------------------------------------
clock_get_timer = softclock_timer_get

;---------------------------------------------------------------
; clock_set_timer
;
; Function:  Set 24 bit 60 Hz timer
;
; Return:    a    bits 0-7
;            x    bits 8-15
;            y    bits 16-23
;
; Note:     The original symbol is SETTIM.
;---------------------------------------------------------------
clock_set_timer = softclock_timer_set

;---------------------------------------------------------------
; clock_get_date_time
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
clock_get_date_time = rtc_get_date_time

;---------------------------------------------------------------
; clock_set_date_time
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
clock_set_date_time = rtc_set_date_time
