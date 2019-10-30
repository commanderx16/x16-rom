lower
	cmp #$0e        ;does he want lower case?
	bne upper       ;branch if not
	lda isomod
	bne outhre
	jsr cpypet2
	jmp loop2

upper
	cmp #$8e        ;does he want upper case
	bne lock        ;branch if not
	lda isomod
	bne outhre
	jsr cpypet1
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
	jsr cpyiso
	lda #$ff
	bne isosto      ;always

isooff
	cmp #$8f        ;switch to PETSCII mode?
	bne outhre      ;branch if not
	jsr cpypet1
	lda #0
isosto	cmp isomod
	beq outhre
	sta isomod
	lda curkbd
	jsr setkbd      ;reload keymap
	jsr clsr        ;clear screen
	jmp loop2

;
runtb	.byt "LOAD",$d,"RUN",$d
;
fkeytb	.byt $8D, "LIST:", 13, 0
	.byt $8D, "M", 'O' + $80, ":", 13, 0
	.byt $8D, "RUN:", 13, 0
	.byt $93, "S", 'C' + $80, "255:", 13, 0
	.byt "LOAD", 13, 0
	.byt "SAVE", '"', 0
	.byt $8D, $93, "DOS",'"', "$",13, 0
	.byt "DOS", '"', 0
;

; rsr 12/08/81 modify for vic-40 keyscan
; rsr  2/17/81 modify for the stinking 6526r2 chip
; rsr  3/11/82 modify for commodore 64
; rsr  3/28/82 modify for new pla
