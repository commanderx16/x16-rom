;----------------------------------------------------------------------
; CIA TOD Clock Driver
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.include "../../../regs.inc"

.export clock_get_date_time, clock_get_timer, clock_set_date_time, clock_set_timer, clock_update

.segment "TIME" ; XXX rename

;
; Strategy:
; * Timer
;   * CIA timer 1 counts to MHZ/60
;   * CIA timer 2 is cascaded, provides bits 0-15 of timer
;   * CIA timer 2 overflow causes IRQ, increments bits 16-23
; * Time
;   * CIA TOD
; * Date
;   * CIA TOD causes IRQ at 0:00:00, increments day (common code)
;

;---------------------------------------------------------------
; clock_update
;
; Function:  Update timer, date and time. Needs to be called
;            every 1/60 seconds on average for accurate state.
;
; Note:     The original symbol is UDTIM.
;---------------------------------------------------------------
clock_update:
	rts ; XXX

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
;
;---------------------------------------------------------------
clock_get_timer:
	lda #0 ; XXX
	tax
	tay
	rts

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
;
;---------------------------------------------------------------
clock_set_timer:
	rts ; XXX

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
;            r3L  jiffies (1/60s)
;---------------------------------------------------------------
clock_get_date_time:
	lda #0  ; XXX
	sta r0L
	sta r0H
	sta r1L
	sta r1H
	sta r2L
	sta r2H
	sta r3L
	rts

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
;            r3L  jiffies (1/60s)
;---------------------------------------------------------------
clock_set_date_time:
	rts ; XXX

