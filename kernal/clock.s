; Clock
;

.include "../regs.inc"
.include "../banks.inc"
.include "../io.inc"

.import datey, datem, dated, timeh, timem, times, timej, timer; [declare]
.import save_ram_bank; [declare]

.export clock_update, clock_get_timer, clock_set_timer, clock_get_time_date, clock_set_time_date

.segment "TIME"

; UDTIM: update time. called every 60th second
;
;interrupts are coming at 60 Hz from VERA's VBLANK
;
clock_update:
;
;increment 24 bit timer
;
	KVARS_START
	inc timer+2     ;increment the timer register
	bne @a
	inc timer+1
	bne @a
	inc timer
@a:

;
;increment time
;
	inc timej       ;jiffies
	lda timej
	cmp #60
	bne @b
	stz timej
	inc times       ;seconds
	lda times
	cmp #60
	bne @b
	stz times
	inc timem       ;minutes
	lda timem
	cmp #60
	bne @b
	stz timem
	inc timeh       ;hours
	lda timeh
	cmp #24
	bne @b
	stz timeh
@b:
;
;increment date
;
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

; RDTIM: read timer. .y=msd, .x=next significant,.a=lsd
;
clock_get_timer:
	KVARS_START
	php
	sei             ;keep timer from rolling
	lda timer+2     ;get lsd
	ldx timer+1     ;get next most sig.
	ldy timer       ;get msd
	plp
	KVARS_END
	rts

; SETTIM: set timer. .y=msd, .x=next significant,.a=lsd
;
clock_set_timer:
	KVARS_START
	php
	sei             ;keep timer from changing
	sta timer+2     ;store lsd
	stx timer+1     ;next most significant
	sty timer       ;store msd
	plp
	KVARS_END
	rts

clock_get_time_date:
	KVARS_START
	php
	sei             ;keep date from rolling
	lda datey
	sta r0L
	lda datem
	sta r0H
	lda dated
	sta r1L
	lda timeh
	sta r1H
	lda timem
	sta r2L
	lda times
	sta r2H
	lda timej
	sta r3L
	plp
	KVARS_END
	rts

clock_set_time_date:
	KVARS_START
	php
	sei             ;keep date from changing
	lda r0L
	sta datey
	lda r0H
	sta datem
	lda r1L
	sta dated
	lda r1H
	sta timeh
	lda r2L
	sta timem
	lda r2H
	sta times
	lda r3L
	sta timej
	plp
	KVARS_END
	rts
