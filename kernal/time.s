	.segment "TIME"
;***********************************
;*                                 *
;* time                            *
;*                                 *
;*consists of three functions:     *
;* (1) udtim-- update time. usually*
;*     called every 60th second.   *
;* (2) settim-- set time. .y=msd,  *
;*     .x=next significant,.a=lsd  *
;* (3) rdtim-- read time. .y=msd,  *
;*     .x=next significant,.a=lsd  *
;*                                 *
;***********************************

;interrupts are coming at 60 Hz from VERA's VBLANK
;

datey	=date + 0; (2000+n)
datem	=date + 1
dated	=date + 2

initdate
	lda #1
	sta datem
	sta dated
	stx datey
	rts

udtim	inc time+2      ;increment the time register
	bne ud30
	inc time+1
	bne ud30
	inc time
;
;here we check for roll-over 23:59:59
;and reset the clock to zero if true
;
ud30	sec
	lda time+2
	sbc #$01
	lda time+1
	sbc #$1a
	lda time
	sbc #$4f
	bcc ud60
;
;time has rolled--zero register
;
	stx time
	stx time+1
	stx time+2
;
;increment date
;
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
	rts
@3:	ldy #1
	sty dated
	inc datem
	lda datem
	cmp #13
	bne @2
	sty datem
	inc datey
ud60	rts

daystab:
	.byte 31, 28, 31, 30, 31, 30
	.byte 31, 31, 30, 31, 30, 31

rdtim	php
	sei             ;keep time from rolling
	lda time+2      ;get lsd
	ldx time+1      ;get next most sig.
	ldy time        ;get msd
	plp
	rts

settim	php
	sei             ;keep time from changing
	sta time+2      ;store lsd
	stx time+1      ;next most significant
	sty time        ;store msd
	plp
	rts

rddat	php
	sei             ;keep date from rolling
	lda dated
	ldx datem
	ldy datey
	plp
	rts

setdat	php
	sei             ;keep date from changing
	sta dated
	stx datem
	sty datey
	plp
	rts

; rsr 8/21/80 remove crfac change stop
; rsr 3/29/82 add shit key check for commodore 64
