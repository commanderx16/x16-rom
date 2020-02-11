;----------------------------------------------------------------------
; Software Date Driver
;----------------------------------------------------------------------
; (C)2020 Michael Steil, License: 2-clause BSD

.export softclock_date_update, softclock_date_get, softclock_date_set

.include "banks.inc"
.include "io.inc"
.include "regs.inc"

.ifp02
.macro bra addr
	jmp addr
.endmacro
.endif

.segment "KVARSB0"

datey:	.res 1           ;    year-1900
datem:	.res 1           ;    month
dated:	.res 1           ;    day

.segment "CLOCK"

;---------------------------------------------------------------
; softclock_date_update
;
; Function:  Increment date by 1 day.
;---------------------------------------------------------------
softclock_date_update:
	KVARS_START
	lda dated
	ora datem
	ora datey
	beq @z          ;date not set, ignore

	ldy datem
	lda daystab-1,y

; leap year logic (correct for 1900-2155)
	cpy #2
	bne @2          ;not February
	tay
	lda datey
	and #3
	bne @1          ;not divisible by 4: no leap year
	lda datey
	beq @1          ;1900: not a leap year
	cmp #200
	beq @1          ;2100: not a leap year
	iny
@1:	tya
@2:
	cmp dated
	beq @3
	inc dated
	bra @z
@3:	ldy #1
	sty dated
	inc datem
	lda datem
	cmp #13
	bne @2
	sty datem
	inc datey
@z:	KVARS_END
	rts

daystab:
	.byte 31, 28, 31, 30, 31, 30
	.byte 31, 31, 30, 31, 30, 31

;---------------------------------------------------------------
; softclock_date_get
;
; Function:  Get the current date
;
; Return:    r0L  year
;            r0H  month
;            r1L  day
;---------------------------------------------------------------
softclock_date_get:
	KVARS_START
	lda datey
	sta r0L
	lda datem
	sta r0H
	lda dated
	sta r1L
	KVARS_END
	rts

;---------------------------------------------------------------
; softclock_date_set
;
; Function:  Set the current date
;
; Pass:      r0L  year
;            r0H  month
;            r1L  day
;---------------------------------------------------------------
softclock_date_set:
	KVARS_START
	lda r0L
	sta datey
	lda r0H
	sta datem
	lda r1L
	sta dated
	KVARS_END
	rts

