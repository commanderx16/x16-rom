;----------------------------------------------------------------------
; Software Timer Driver
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.export softclock_timer_update, softclock_timer_get, softclock_timer_set

.include "banks.inc"
.include "io.inc"

.segment "KVARSB0"

timer:	.res 3           ;$A0 24 bit 1/60th second timer

.segment "CLOCK"

;---------------------------------------------------------------
; softclock_timer_update
;
; Function:  Increment 24-bit timer
;---------------------------------------------------------------
softclock_timer_update:
	KVARS_START
	inc timer+2     ;increment the timer register
	bne :+
	inc timer+1
	bne :+
	inc timer
:	KVARS_END
	rts

;---------------------------------------------------------------
; softclock_timer_get
;
; Function:  Return 24 bit 60 Hz timer
;
; Return:    a    bits 0-7
;            x    bits 8-15
;            y    bits 16-23
;
; Note:     This can be used as 'clock_get_timer' (RDTIM).
;---------------------------------------------------------------
softclock_timer_get:
	KVARS_START
	php
	sei             ;keep timer from rolling
	lda timer+2
	ldx timer+1
	ldy timer
	plp
	KVARS_END
	rts

;---------------------------------------------------------------
; softclock_timer_set
;
; Function:  Set 24 bit 60 Hz timer
;
; Return:    a    bits 0-7
;            x    bits 8-15
;            y    bits 16-23
;
; Note:     This can be used as 'clock_set_timer' (SETTIM).
;---------------------------------------------------------------
softclock_timer_set:
	KVARS_START
	php
	sei             ;keep timer from rolling
	sta timer+2
	stx timer+1
	sty timer
	plp
	KVARS_END
	rts


