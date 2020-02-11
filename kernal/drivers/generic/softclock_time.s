;----------------------------------------------------------------------
; Software Time Driver
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.export softclock_time_update, softclock_time_get, softclock_time_set

.include "banks.inc"
.include "io.inc"
.include "regs.inc"

.ifp02
.macro stz addr
	lda #0
	sta addr
.endmacro
.endif

.segment "KVARSB0"

timeh:	.res 1           ;    hours
timem:	.res 1           ;    minutes
times:	.res 1           ;    seconds
timej:	.res 1           ;    jiffies

.segment "CLOCK"

;---------------------------------------------------------------
; softclock_time_update
;
; Function:  Increment time by 1 jiffy.
;
; Pass:      .A   jiffies per second (usually 60)
;
; Return:    .Z   set if midnight is reached
;---------------------------------------------------------------
softclock_time_update:
	KVARS_START
	inc timej       ;jiffies
	cmp timej
	bne :+
	stz timej
	inc times       ;seconds
	lda times
	cmp #60
	bne :+
	stz times
	inc timem       ;minutes
	lda timem
	cmp #60
	bne :+
	stz timem
	inc timeh       ;hours
	lda timeh
	cmp #24
	bne :+
	stz timeh
:	KVARS_END
	rts

;---------------------------------------------------------------
; softclock_time_get
;
; Function:  Get the current time
;
; Return:    r1H  hours
;            r2L  minutes
;            r2H  seconds
;            r3L  jiffies
;---------------------------------------------------------------
softclock_time_get:
	KVARS_START
	lda timeh
	sta r1H
	lda timem
	sta r2L
	lda times
	sta r2H
	lda timej
	sta r3L
	KVARS_END
	rts

;---------------------------------------------------------------
; softclock_time_set
;
; Function:  Set the current time
;
; Pass:      r1H  hours
;            r2L  minutes
;            r2H  seconds
;            r3L  jiffies
;---------------------------------------------------------------
softclock_time_set:
	KVARS_START
	lda r1H
	sta timeh
	lda r2L
	sta timem
	lda r2H
	sta times
	lda r3L
	sta timej
	KVARS_END
	rts

