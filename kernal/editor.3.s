lower
	cmp #$0e        ;does he want lower case?
	bne upper       ;branch if not
	jsr lowup
	ora #8 >> 2
	bne ulset

upper
	cmp #$8e        ;does he want upper case
	bne lock        ;branch if not
	jsr lowup
	and #$ff-(8 >> 2)
ulset	sta veradat
outhre	jmp loop2

lock
	cmp #8          ;does he want to lock in this mode?
	bne unlock      ;branch if not
	lda #$80        ;else set lock switch on
	ora mode        ;don't hurt anything - just in case
	bmi lexit

unlock
	cmp #9          ;does he want to unlock the keyboard?
	bne isoon       ;branch if not
	lda #$7f        ;clear the lock switch
	and mode        ;dont hurt anything
lexit	sta mode
	jmp loop2       ;get out

isoon
	cmp #$0f        ;switch to ISO mode?
	bne isooff      ;branch if not
	jsr lowup
	ldx #isobas >> 10
	lda #$ff
	bne isosto      ;always

isooff
	cmp #$8f        ;switch to PETSCII mode?
	bne outhre      ;branch if not
	jsr lowup
	ldx #tilbas >> 10
	lda #0
isosto	cmp isomod
	beq outhre
	stx veradat
	sta isomod
	jsr clsr        ;clear screen
	jmp loop2

; access VERA register TILE_BASE_HI
lowup	lda #$05        ;$F2005: layer 1, TILE_BASE_HI
	sta veralo
	lda #$20
	sta veramid
	lda #$0F
	sta verahi
	lda veradat
	rts

;
runtb	.byt "LOAD",$d,"RUN",$d
;
fkeytb	.byt $8D, "LIST:", 13, 0
	.byt $8D, "M", 'O' + $80, ":", 13, 0
	.byt $8D, "RUN:", 13, 0
	.byt $93, "S", 'Y' + $80, "65375:", 13, 0
	.byt "LOAD", 13, 0
	.byt "SAVE", '"', 0
	.byt $8D, $93, "DOS",'"', "$",13, 0
	.byt "DOS", '"', 0
;

; rsr 12/08/81 modify for vic-40 keyscan
; rsr  2/17/81 modify for the stinking 6526r2 chip
; rsr  3/11/82 modify for commodore 64
; rsr  3/28/82 modify for new pla
