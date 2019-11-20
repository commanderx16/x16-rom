; GEOS KERNAL by Berkeley Softworks
; reverse engineered by Maciej Witkowiak, Michael Steil
;
; C64/CIA clock driver

.include "const.inc"
.include "geossym.inc"
.include "geosmac.inc"
.include "config.inc"
.include "kernal.inc"
.include "c64.inc"

.import alarmWarnFlag

.global _DoUpdateTime

.segment "time1"

_DoUpdateTime:
	; XXX TODO * read clock from KERNAL
	;          * convert into h:m:s
	;          * store y-m-d h:m:s in year/month/dat/hour/minutes/seconds
	ldy #5
:	lda dateCopy,y
	sta year,y
	dey
	bpl :-
.if 0	; XXX TODO alarm logic
	bbrf 7, alarmSetFlag, @5
	and #ALARMMASK
	beq @6
	lda #$4a
	sta alarmSetFlag
	lda alarmTmtVector
	ora alarmTmtVector+1
	beq @5
	jmp (alarmTmtVector)
@5:	bbrf 6, alarmSetFlag, @6
	; XXX TODO bell
@6:
.endif
	rts

dateCopy:
	.byte 19,09,27
	.byte 9,41,0
