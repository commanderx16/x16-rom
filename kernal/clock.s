; Clock
;

.include "../banks.inc"
.include "../io.inc"

.import time, date; [declare]
.import save_ram_bank; [declare]

.export clock_init, clock_update, clock_get_timer, clock_set_timer, clock_get_date, clock_set_date

datey	=date + 0; (2000+n)
datem	=date + 1
dated	=date + 2

.segment "TIME"

clock_init:
	KVARS_START
	lda #1
	sta datem
	sta dated
	stx datey
	KVARS_END
	rts

; UDTIM: update time. called every 60th second
;
;interrupts are coming at 60 Hz from VERA's VBLANK
;
clock_update:
	KVARS_START
	inc time+2      ;increment the time register
	bne @a
	inc time+1
	bne @a
	inc time
;
;here we check for roll-over 23:59:59
;and reset the clock to zero if true
;
@a:	sec
	lda time+2
	sbc #$01
	lda time+1
	sbc #$1a
	lda time
	sbc #$4f
	bcc @z
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

; RDTIM: read timer. .y=msd, .x=next significant,.a=lsd
;
clock_get_timer:
	KVARS_START
	php
	sei             ;keep time from rolling
	lda time+2      ;get lsd
	ldx time+1      ;get next most sig.
	ldy time        ;get msd
	plp
	KVARS_END
	rts

; SETTIM: set timer. .y=msd, .x=next significant,.a=lsd
;
clock_set_timer:
	KVARS_START
	php
	sei             ;keep time from changing
	sta time+2      ;store lsd
	stx time+1      ;next most significant
	sty time        ;store msd
	plp
	KVARS_END
	rts

clock_get_date:
	KVARS_START
	php
	sei             ;keep date from rolling
	lda dated
	ldx datem
	ldy datey
	plp
	KVARS_END
	rts

clock_set_date:
	KVARS_START
	php
	sei             ;keep date from changing
	sta dated
	stx datem
	sty datey
	plp
	KVARS_END
	rts
